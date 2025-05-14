use clap::Parser;
use std::path::PathBuf;

/// A simple tool to switch active ssh key pairs
#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
pub struct Args {
    /// Path to the configuration file
    #[arg(short, long)]
    pub config: Option<PathBuf>,

    /// Role names
    #[arg(short, long)]
    pub roles: Vec<String>,

    /// Key pair name
    #[arg(short, long)]
    pub pair: String,
}
