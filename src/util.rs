use bytes::Bytes;
use pulldown_cmark::{html, Options, Parser};
use warp::Filter;

pub fn string_filter(
    limit: u64,
) -> impl Filter<Extract = (String,), Error = warp::Rejection> + Clone {
    warp::body::content_length_limit(limit)
        .and(warp::filters::body::bytes())
        .and_then(convert_to_string)
}

async fn convert_to_string(bytes: Bytes) -> Result<String, warp::Rejection> {
    String::from_utf8(bytes.to_vec()).map_err(|_| warp::reject())
}

pub fn render_markdown(markdown: &str) -> String {
    let parser = Parser::new_ext(markdown, Options::all());
    let mut html_output = String::new();
    html::push_html(&mut html_output, parser);
    html_output
}

pub fn file_names(path: &str) -> std::io::Result<Vec<String>> {
    let entries = std::fs::read_dir(path)?;
    let mut pairs: Vec<_> = entries
        .filter_map(|entry| {
            entry.ok().and_then(|e| {
                e.metadata()
                    .ok()
                    .map(|m| (e.file_name().into_string().unwrap(), m))
            })
        })
        .collect();
    pairs.sort_by(|a, b| b.1.modified().unwrap().cmp(&a.1.modified().unwrap()));
    Ok(pairs
        .into_iter()
        .filter_map(|(s, _)| {
            if s.ends_with(".md") {
                Some(s[..s.len() - 3].to_string())
            } else {
                None
            }
        })
        .collect())
}

#[macro_export]
macro_rules! route {
    ($x:ty) => (impl Filter<Extract = ($x,), Error = warp::Rejection> + Clone)
}
