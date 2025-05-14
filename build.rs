use clap::{CommandFactory, ValueEnum};
use clap_complete::{Shell, generate_to};
use std::io::Error;

include!("src/cli.rs");

fn main() -> Result<(), Error> {
    let outdir = "target";

    let mut cmd = Args::command();
    for &shell in Shell::value_variants() {
        generate_to(shell, &mut cmd, "ski", &outdir)?;
    }

    Ok(())
}
