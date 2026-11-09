# Rendered by .github/workflows/release.yml in canassa/zorg; do not edit in the tap.
class Zorg < Formula
  desc "Zig compiler fork with a self-hosted AArch64 backend"
  homepage "https://github.com/canassa/zorg"
  version "0.17.1-zorg.3"
  license "MIT"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+-zorg\.\d+)$/i)
    strategy :github_latest
  end

  on_macos do
    depends_on arch: :arm64

    on_arm do
      url "https://github.com/canassa/zorg/releases/download/v0.17.1-zorg.3/zorg-aarch64-macos-0.17.1-zorg.3.tar.xz"
      sha256 "fc34363b635ed1a1e2e37a32364dffef304a52c3c6b04d8796496501dad22ef7"
    end
  end
  on_linux do
    on_arm do
      url "https://github.com/canassa/zorg/releases/download/v0.17.1-zorg.3/zorg-aarch64-linux-0.17.1-zorg.3.tar.xz"
      sha256 "f300239f2f4e7f1e519c6346fb5adc5a2d93f34e8c7188728f20ea3e502fa283"
    end
    on_intel do
      url "https://github.com/canassa/zorg/releases/download/v0.17.1-zorg.3/zorg-x86_64-linux-0.17.1-zorg.3.tar.xz"
      sha256 "953ab4c9d90a9e0b0e53138e64ed03b2fbf43eeddc5763a7a3b9a5adc1e6dbc5"
    end
  end

  # Keep the bundled std, libc and headers exactly as shipped.
  skip_clean "libexec"

  def install
    # Flat tarball: zorg, lib/, LICENSE, README.md. zorg resolves the symlink
    # to libexec/zorg and finds libexec/lib.
    libexec.install Dir["*"]
    bin.install_symlink libexec/"zorg"
  end

  test do
    ENV["ZORG_GLOBAL_CACHE_DIR"] = (testpath/"cache").to_s
    assert_equal version.to_s.sub("-zorg.", "+zorg."), shell_output("#{bin}/zorg version").strip
    assert_match "#{libexec}/lib", shell_output("#{bin}/zorg env")

    (testpath/"hello.zig").write <<~ZIG
      const std = @import("std");
      pub fn main(init: std.process.Init) !void {
          try std.Io.File.stdout().writeStreamingAll(init.io, "Hello, world!");
      }
    ZIG
    system bin/"zorg", "build-exe", "hello.zig", "-fllvm"
    assert_equal "Hello, world!", shell_output("./hello")
    if Hardware::CPU.arm?
      system bin/"zorg", "build-exe", "hello.zig", "-fno-llvm", "--name", "hello-self"
      assert_equal "Hello, world!", shell_output("./hello-self")
    end

    ENV.delete "CPATH"
    (testpath/"hello.c").write "#include <stdio.h>\nint main(void) { fputs(\"hi\", stdout); return 0; }\n"
    system bin/"zorg", "cc", "hello.c", "-o", "hello-c"
    assert_equal "hi", shell_output("./hello-c")
  end
end
