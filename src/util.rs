use bytes::Bytes;
use pulldown_cmark::{html, Options, Parser};
use warp::Filter;

#[macro_export]
macro_rules! route {
    ($x:ty) => (impl Filter<Extract = ($x,), Error = warp::Rejection> + Clone)
}

pub fn string_body(limit: u64) -> route!(String) {
    warp::body::content_length_limit(limit)
        .and(warp::filters::body::bytes())
        .and_then(bytes_to_string)
}

async fn bytes_to_string(bytes: Bytes) -> Result<String, warp::Rejection> {
    String::from_utf8(bytes.to_vec()).map_err(|_| warp::reject())
}

pub fn render_markdown(markdown: &str) -> String {
    let parser = Parser::new_ext(markdown, Options::all());
    let mut html_output = String::new();
    html::push_html(&mut html_output, parser);
    html_output
}

pub fn file_names(path: &str, extension: &str) -> std::io::Result<Vec<String>> {
    let entries = std::fs::read_dir(path)?;
    let mut pairs: Vec<_> = entries
        .filter_map(|entry| {
            entry.ok().and_then(|e| {
                e.metadata()
                    .ok()
                    .map(|m| (e.file_name().into_string().unwrap(), m.modified().unwrap()))
            })
        })
        .collect();
    pairs.sort_by(|a, b| a.1.cmp(&b.1));
    Ok(pairs
        .into_iter()
        .filter_map(|(s, _)| {
            if s.ends_with(extension) {
                Some(s[..s.len() - extension.len()].to_string())
            } else {
                None
            }
        })
        .collect())
}

use std::io::prelude::*;

pub fn read_until_delimiter(file_path: String, delimiter: &str) -> std::io::Result<String> {
    let file = std::fs::File::open(file_path)?;
    let mut reader = std::io::BufReader::new(file);
    let mut result = String::new();
    let mut line = String::new();
    while let Ok(n) = reader.read_line(&mut line) {
        if n == 0 || line == format!("{}\n", delimiter) {
            break;
        }
        result.push_str(&line);
        line = String::new();
    }
    Ok(result)
}
