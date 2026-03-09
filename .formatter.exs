[
  import_deps: [
    :ash,
    :ash_archival,
    :ash_authentication,
    :ash_double_entry,
    :ash_money,
    :ash_oban,
    :ash_paper_trail,
    :ash_phoenix,
    :ash_postgres,
    :ash_state_machine,
    :ecto,
    :ecto_sql,
    :phoenix
  ],
  subdirectories: ["priv/*/migrations"],
  plugins: [Phoenix.LiveView.HTMLFormatter],
  inputs: ["*.{heex,ex,exs}", "{config,lib,test}/**/*.{heex,ex,exs}", "priv/*/seeds.exs"]
]
