use serde::Deserialize;
use std::{collections::HashMap, path::PathBuf};

#[derive(Debug, Default, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Config {
    pub roles: HashMap<String, Role>,
    pub pairs: HashMap<String, Pair>,
}

#[derive(Debug, Default, Deserialize, Clone)]
#[serde(deny_unknown_fields)]
pub struct Role {
    pub target: PathBuf,
}

#[derive(Debug, Default, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Pair {
    pub name: Option<PathBuf>,
    pub public: Option<PathBuf>,
    pub private: Option<PathBuf>,
    pub default_roles: Vec<String>,
}
