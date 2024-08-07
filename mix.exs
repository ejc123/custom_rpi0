defmodule NervesSystemRpi0.MixProject do
  use Mix.Project

  @github_organization "ejc123"
  @app :custom_rpi0
  @source_url "https://github.com/#{@github_organization}/#{@app}"
  @version Path.join(__DIR__, "VERSION")
           |> File.read!()
           |> String.trim()

  def project do
    [
      app: @app,
      version: @version,
      # Because we're using OTP 27, we need to enforce Elixir 1.17 or later.
      elixir: "~> 1.17",
      compilers: Mix.compilers() ++ [:nerves_package],
      nerves_package: nerves_package(),
      description: description(),
      package: package(),
      deps: deps(),
      aliases: [loadconfig: [&bootstrap/1]],
      docs: docs(),
      preferred_cli_env: %{
        docs: :docs,
        "hex.build": :docs,
        "hex.publish": :docs
      }
    ]
  end

  def application do
    check_rpi_v2_ack!()
    []
  end

  defp bootstrap(args) do
    set_target()
    Application.start(:nerves_bootstrap)
    # We're compiling locally so ack v2 req
    Application.put_env(:nerves, :rpi_v2_ack, true)
    Mix.Task.run("loadconfig", args)
  end

  defp nerves_package do
    [
      type: :system,
      artifact_sites: [
        {:github_releases, "#{@github_organization}/#{@app}"}
      ],
      build_runner_opts: build_runner_opts(),
      platform: Nerves.System.BR,
      platform_config: [
        defconfig: "nerves_defconfig"
      ],
      # The :env key is an optional experimental feature for adding environment
      # variables to the crosscompile environment. These are intended for
      # llvm-based tooling that may need more precise processor information.
      env: [
        {"TARGET_ARCH", "arm"},
        {"TARGET_CPU", "arm1176jzf_s"},
        {"TARGET_OS", "linux"},
        {"TARGET_ABI", "gnueabihf"},
        {"TARGET_GCC_FLAGS",
         "-mabi=aapcs-linux -mfpu=vfp -marm -fstack-protector-strong -mfloat-abi=hard -mcpu=arm1176jzf-s -fPIE -pie -Wl,-z,now -Wl,-z,relro"}
      ],
      checksum: package_files()
    ]
  end

  defp deps do
    [
      {:nerves, "~> 1.11", runtime: false},
      {:nerves_system_br, "1.28.1", runtime: false},
      {:nerves_toolchain_armv6_nerves_linux_gnueabihf, "~> 13.2.0", runtime: false},
      {:nerves_system_linter, "~> 0.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.22", only: :docs, runtime: false}
    ]
  end

  defp description do
    """
    Nerves System - Raspberry Pi Zero and Zero W
    """
  end

  defp docs do
    [
      extras: ["README.md", "CHANGELOG.md"],
      main: "readme",
      assets: %{"assets" => "./assets"},
      source_ref: "v#{@version}",
#      source_url: @source_url,
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end

  defp package do
    [
      maintainers: ["Eric J. Christeson"],
      files: package_files(),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp package_files do
    [
      "fwup_include",
      "rootfs_overlay",
      "CHANGELOG.md",
      "cmdline.txt",
      "config.txt",
      "fwup-ops.conf",
      "fwup.conf",
      "LICENSE",
      "linux-6.6.defconfig",
      "mix.exs",
      "nerves_defconfig",
      "nerves_initramfs.conf",
      "post-build.sh",
      "post-createfs.sh",
      "ramoops.dts",
      "README.md",
      "VERSION"
    ]
  end

  defp build_runner_opts() do
    # Download source files first to get download errors right away.
    [make_args: primary_site() ++ ["source", "all", "legal-info"]]
  end

  defp primary_site() do
    case System.get_env("BR2_PRIMARY_SITE") do
      nil -> []
      primary_site -> ["BR2_PRIMARY_SITE=#{primary_site}"]
    end
  end

  defp set_target() do
    if function_exported?(Mix, :target, 1) do
      apply(Mix, :target, [:target])
    else
      System.put_env("MIX_TARGET", "target")
    end
  end

  defp check_rpi_v2_ack!() do
    acked? = Application.get_env(:nerves, :rpi_v2_ack) || System.get_env("NERVES_RPI_V2_ACK")

    unless acked? do
      Mix.raise("""


      You are using #{@app} >= 2.0.0 which is technically
      backwards compatible, but requires one manual step if
      you are attempting to update the firmware on an existing
      device via ssh, upload script, NervesHub, or other remote
      firmware update procedure.

      You will need to validate the running firmware on the
      device before installing a firmware built with this system.
      Otherwise, you will get an unexpected and misleading fwup error.

      To validate and avoid the fwup error, run:

        Nerves.Runtime.validate_firmware()

      Or if using :nerves_runtime < 0.11.2, run:

        Nerves.Runtime.KV.put("nerves_fw_validated", "1")

      If you are burning the firmware directly to a SD card, then
      nothing needs to be done.

      To allow compilation to complete, acknowledge you have read
      this warning by adding this line to your `config.exs`:

        config :nerves, rpi_v2_ack: true
      """)
    end
  end
end
