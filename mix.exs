defmodule Frobots.Umbrella.MixProject do
  use Mix.Project

  {:ok, ver} = File.read("./release.version")
  {arch, _} = System.cmd("uname", ["-m"])

  @version with {_osfamily, osname} = :os.type(),
             do: ~s"#{Atom.to_string(osname)}_#{String.trim(arch)}_#{String.trim(ver)}"

  def project do
    [
      apps_path: "apps",
      version: @version,
      start_permanent: Mix.env() == :prod || Mix.env() == :staging,
      deps: deps(),
      aliases: aliases(),
      releases: releases()
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options.
  #
  # Dependencies listed here are available only for this project
  # and cannot be accessed from applications inside the apps/ folder.

  defp deps do
    [
      {:bakeware, "~> 0.2"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  #
  # Aliases listed here are available only for this project
  # and cannot be accessed from applications inside the apps/ folder.

  defp aliases do
    [
      # run `mix setup` in all child apps
      setup: ["cmd mix setup"],
      go: ["cmd source ../../.env ; mix run"],
      test_path: ["cmd pwd"]
    ]
  end

  defp releases do
    [
      frobots_client: [
        version: @version,
        applications: [frobots_scenic: :permanent, frobots: :permanent],
        include_executables_for: [:unix, :windows],
        steps: [:assemble, :tar]
      ],
      frobots: [
        version: @version,
        applications: [frobots_scenic: :permanent, frobots: :permanent],
        include_executables_for: [:unix, :windows],
        steps: [:assemble, :tar]
      ],
      local: [
        version: @version,
        applications: [frobots_scenic: :permanent, frobots: :permanent],
        include_executables_for: [:unix, :windows],
        steps: [:assemble, :tar, &Bakeware.assemble/1],
        bakeware: [
          compression_level: 1,
          start_command: "daemon"
        ]
      ]
    ]
  end
end
