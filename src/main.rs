mod cli;
mod config;

use clap::Parser;
use color_eyre::eyre::{Context, OptionExt, eyre};
use config::Config;
use std::{
    fs::{read_to_string, remove_file},
    os::unix::fs::symlink,
    path::Path,
};

fn main() -> color_eyre::Result<()> {
    color_eyre::install()?;
    let path = dirs::home_dir()
        .ok_or_eyre("Failed to get user home directory")?
        .join(".ssh/");
    let args = cli::Args::parse();
    let config_str = read_to_string(args.config.as_ref().unwrap_or(&path.join("ski.toml")))
        .wrap_err("Failed to open config file")?;
    let config: Config = toml::from_str(&config_str)?;

    if let Some(pair) = config.pairs.get(&args.pair) {
        let mut pair_pub = path.join(pair.public.clone().unwrap_or_else(|| {
            pair.name
                .clone()
                .unwrap_or_else(|| args.pair.clone().into())
        }));
        pair_pub.set_extension("pub");
        let pair_priv = path.join(pair.private.clone().unwrap_or_else(|| {
            pair.name
                .clone()
                .unwrap_or_else(|| args.pair.clone().into())
        }));

        let mut roles = args.roles;
        if roles.len() == 0 {
            if let Some(d) = &pair.default_roles {
                roles.append(&mut d.clone());
            }
        }
        for role in roles {
            if let Some(role) = config.roles.get(&role) {
                if role.target.is_absolute() {
                    return Err(eyre!(
                        "Role target {} may not be an absolute path",
                        role.target.display()
                    ));
                } else {
                    let mut target_path = path.join(role.target.clone());
                    link(&pair_priv, &target_path)?;
                    if target_path.set_extension("pub") {
                        link(&pair_pub, &target_path)?;
                    }
                }
            } else {
                return Err(eyre!("Role {} not defined", role));
            }
        }
    } else {
        return Err(eyre!("Pair {} not defined", args.pair));
    }
    Ok(())
}

fn link(source: &Path, target: &Path) -> color_eyre::Result<()> {
    let target_exists = target.try_exists()?;
    if (target_exists && target.is_symlink()) || !target_exists {
        if source.try_exists()? {
            if target_exists {
                remove_file(target)?;
            }
            symlink(source, target)?;
        } else {
            return Err(eyre!("Source key {} does not exist", source.display()));
        }
    } else if target_exists {
        return Err(eyre!(
            "Role target {} exists but is not a symlink",
            target.display()
        ));
    }
    Ok(())
}
