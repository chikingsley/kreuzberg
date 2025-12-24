// Command download-binaries downloads pre-built kreuzberg-ffi binaries from GitHub releases.
//
// Usage:
//   go run scripts/go/download-binaries.go [options]
//
// This tool:
//   - Detects the current OS/architecture (darwin/linux, amd64/arm64)
//   - Attempts to download the pre-built FFI binary from the latest GitHub release
//   - Extracts to a user/system location based on the installation method
//   - Falls back to building from source if download fails
//   - Sets up environment variables for runtime library discovery
//
// Options:
//   -tag string         Release tag (default: auto-detect latest)
//   -dest string        Installation destination (default: ~/.local or system)
//   -skip-build-fallback Don't attempt to build from source if download fails
//   -verbose            Verbose output
package main

import (
	"archive/tar"
	"compress/gzip"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"time"
)

func main() {
	tag := flag.String("tag", "", "Release tag (default: auto-detect latest)")
	dest := flag.String("dest", "", "Installation destination")
	skipBuildFallback := flag.Bool("skip-build-fallback", false, "Don't build from source if download fails")
	verbose := flag.Bool("verbose", false, "Verbose output")
	flag.Parse()

	if err := run(*tag, *dest, *skipBuildFallback, *verbose); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}

func run(tag, dest string, skipBuildFallback, verbose bool) error {
	// Detect platform
	platform, arch, err := detectPlatform()
	if err != nil {
		return fmt.Errorf("platform detection failed: %w", err)
	}
	if verbose {
		fmt.Printf("Detected platform: %s/%s\n", platform, arch)
	}

	// Auto-detect release tag if not provided
	if tag == "" {
		latestTag, err := getLatestReleaseTag(verbose)
		if err != nil {
			return fmt.Errorf("failed to detect latest release: %w", err)
		}
		tag = latestTag
		if verbose {
			fmt.Printf("Using latest release tag: %s\n", tag)
		}
	}

	// Construct artifact name
	artifactName := fmt.Sprintf("go-ffi-%s-%s.tar.gz", platform, arch)
	if verbose {
		fmt.Printf("Target artifact: %s\n", artifactName)
	}

	// Determine installation destination
	if dest == "" {
		var err error
		dest, err = getDefaultDestination(verbose)
		if err != nil {
			return fmt.Errorf("failed to determine installation destination: %w", err)
		}
	}
	if verbose {
		fmt.Printf("Installation destination: %s\n", dest)
	}

	// Try to download
	if err := downloadAndInstall(tag, artifactName, dest, verbose); err != nil {
		if verbose {
			fmt.Printf("Download failed: %v\n", err)
		}

		if skipBuildFallback {
			return err
		}

		fmt.Println("Falling back to building from source...")
		if err := buildFromSource(verbose); err != nil {
			return fmt.Errorf("both download and build failed: %w", err)
		}
		return nil
	}

	fmt.Println("Installation complete!")
	if err := printEnvSetup(dest); err != nil {
		fmt.Fprintf(os.Stderr, "Warning: Failed to print env setup: %v\n", err)
	}
	return nil
}

func detectPlatform() (platform, arch string, err error) {
	platform = runtime.GOOS
	arch = runtime.GOARCH

	// Map Go arch names to release artifact names
	archMap := map[string]string{
		"amd64": "x86_64",
		"arm64": "arm64",
	}

	if mappedArch, ok := archMap[arch]; ok {
		arch = mappedArch
	}

	// Validate
	switch platform {
	case "linux", "darwin", "windows":
		// OK
	default:
		return "", "", fmt.Errorf("unsupported platform: %s", platform)
	}

	switch arch {
	case "x86_64", "arm64":
		// OK
	default:
		return "", "", fmt.Errorf("unsupported architecture: %s", arch)
	}

	return
}

type GithubRelease struct {
	TagName string `json:"tag_name"`
	Assets  []struct {
		Name string `json:"name"`
		URL  string `json:"browser_download_url"`
	} `json:"assets"`
}

func getLatestReleaseTag(verbose bool) (string, error) {
	url := "https://api.github.com/repos/kreuzberg-dev/kreuzberg/releases/latest"
	if verbose {
		fmt.Printf("Fetching latest release from: %s\n", url)
	}

	resp, err := httpGet(url)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		body, _ := io.ReadAll(resp.Body)
		return "", fmt.Errorf("API returned %d: %s", resp.StatusCode, string(body))
	}

	var release GithubRelease
	if err := json.NewDecoder(resp.Body).Decode(&release); err != nil {
		return "", fmt.Errorf("failed to decode release info: %w", err)
	}

	if release.TagName == "" {
		return "", fmt.Errorf("no releases found")
	}

	return release.TagName, nil
}

func downloadAndInstall(tag, artifactName, dest string, verbose bool) error {
	// Find asset URL
	url := fmt.Sprintf("https://api.github.com/repos/kreuzberg-dev/kreuzberg/releases/tags/%s", tag)
	if verbose {
		fmt.Printf("Fetching release info from: %s\n", url)
	}

	resp, err := httpGet(url)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("API returned %d: %s", resp.StatusCode, string(body))
	}

	var release GithubRelease
	if err := json.NewDecoder(resp.Body).Decode(&release); err != nil {
		return fmt.Errorf("failed to decode release info: %w", err)
	}

	downloadURL := ""
	for _, asset := range release.Assets {
		if asset.Name == artifactName {
			downloadURL = asset.URL
			break
		}
	}

	if downloadURL == "" {
		return fmt.Errorf("artifact %s not found in release %s", artifactName, tag)
	}

	if verbose {
		fmt.Printf("Downloading from: %s\n", downloadURL)
	}

	// Download file
	resp, err = httpGet(downloadURL)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("download returned %d: %s", resp.StatusCode, string(body))
	}

	// Extract to destination
	if err := extractTarGz(resp.Body, dest, verbose); err != nil {
		return fmt.Errorf("extraction failed: %w", err)
	}

	return nil
}

func extractTarGz(src io.Reader, dest string, verbose bool) error {
	// Create destination if needed
	if err := os.MkdirAll(dest, 0755); err != nil {
		return fmt.Errorf("failed to create destination: %w", err)
	}

	gz, err := gzip.NewReader(src)
	if err != nil {
		return fmt.Errorf("failed to create gzip reader: %w", err)
	}
	defer gz.Close()

	tr := tar.NewReader(gz)

	for {
		header, err := tr.Next()
		if err == io.EOF {
			break
		}
		if err != nil {
			return fmt.Errorf("tar error: %w", err)
		}

		targetPath := filepath.Join(dest, header.Name)
		targetDir := filepath.Dir(targetPath)

		if err := os.MkdirAll(targetDir, 0755); err != nil {
			return fmt.Errorf("failed to create directory %s: %w", targetDir, err)
		}

		if header.Typeflag == tar.TypeDir {
			if err := os.MkdirAll(targetPath, 0755); err != nil {
				return err
			}
		} else if header.Typeflag == tar.TypeReg {
			f, err := os.Create(targetPath)
			if err != nil {
				return fmt.Errorf("failed to create file %s: %w", targetPath, err)
			}

			if _, err := io.Copy(f, tr); err != nil {
				f.Close()
				return fmt.Errorf("failed to write file %s: %w", targetPath, err)
			}
			f.Close()

			if err := os.Chmod(targetPath, os.FileMode(header.Mode)); err != nil {
				return err
			}

			if verbose {
				fmt.Printf("  Extracted: %s\n", header.Name)
			}
		}
	}

	return nil
}

func getDefaultDestination(verbose bool) (string, error) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return "", fmt.Errorf("failed to get home directory: %w", err)
	}

	// Default to ~/.local (user-local installation, no sudo required)
	dest := filepath.Join(homeDir, ".local")
	if verbose {
		fmt.Printf("Using user-local destination: %s\n", dest)
	}

	return dest, nil
}

func buildFromSource(verbose bool) error {
	fmt.Println("Building kreuzberg-ffi from source...")

	cmd := exec.Command("cargo", "build", "-p", "kreuzberg-ffi", "--release")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	if err := cmd.Run(); err != nil {
		return fmt.Errorf("cargo build failed: %w", err)
	}

	fmt.Println("Build completed successfully!")
	return nil
}

func printEnvSetup(dest string) error {
	libPath := filepath.Join(dest, "lib")
	pkgConfigPath := filepath.Join(dest, "share", "pkgconfig")

	fmt.Println("\nTo use the installed FFI library, add to your shell profile (~/.bashrc, ~/.zshrc, etc.):")
	fmt.Println()
	fmt.Printf("export PKG_CONFIG_PATH=\"%s:$PKG_CONFIG_PATH\"\n", pkgConfigPath)

	if runtime.GOOS == "linux" {
		fmt.Printf("export LD_LIBRARY_PATH=\"%s:$LD_LIBRARY_PATH\"\n", libPath)
	} else if runtime.GOOS == "darwin" {
		fmt.Printf("export DYLD_FALLBACK_LIBRARY_PATH=\"%s:$DYLD_FALLBACK_LIBRARY_PATH\"\n", libPath)
	}

	fmt.Println()
	fmt.Println("Then reload your shell: exec $SHELL")
	return nil
}

func httpGet(url string) (*http.Response, error) {
	client := &http.Client{
		Timeout: 30 * time.Second,
	}

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, err
	}

	// GitHub API requires User-Agent
	req.Header.Set("User-Agent", "kreuzberg-go-binaries-installer")

	return client.Do(req)
}
