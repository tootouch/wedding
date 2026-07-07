# frozen_string_literal: true
# encoding: UTF-8

require "fileutils"

ROOT = File.expand_path("..", __dir__)
ASSETS_DIR = File.join(ROOT, "assets")
ORDER_FILE = File.join(ASSETS_DIR, "order.txt")
LARGE_DIR = File.join(ASSETS_DIR, "gallery-large")
THUMB_DIR = File.join(ASSETS_DIR, "gallery-thumb")
MANIFEST_FILE = File.join(ASSETS_DIR, "gallery-manifest.js")
SCRIPT_FILE = File.join(ROOT, "script.js")
INDEX_FILE = File.join(ROOT, "index.html")
VERSION = ENV.fetch("GALLERY_VERSION") { "gallery-#{Time.now.strftime("%Y%m%d%H%M%S")}" }

def run_sips(*args)
  system("sips", *args, out: File::NULL, err: File::NULL) || abort("sips failed: #{args.join(' ')}")
end

def gallery_items(count, quoted_keys:)
  (1..count).map do |index|
    number = format("%03d", index)
    if quoted_keys
      <<~ITEM.chomp
        {
          "src": "assets/gallery-large/gallery-#{number}.jpg?v=#{VERSION}",
          "thumb": "assets/gallery-thumb/gallery-#{number}.jpg?v=#{VERSION}",
          "alt": "재혁과 소진의 웨딩 사진 #{index}",
          "caption": "재혁과 소진의 웨딩 사진"
        }
      ITEM
    else
      <<~ITEM.chomp
        {
          src: "assets/gallery-large/gallery-#{number}.jpg?v=#{VERSION}",
          thumb: "assets/gallery-thumb/gallery-#{number}.jpg?v=#{VERSION}",
          alt: "재혁과 소진의 웨딩 사진 #{index}",
          caption: "재혁과 소진의 웨딩 사진",
        }
      ITEM
    end
  end
end

ordered_files = File.readlines(ORDER_FILE, chomp: true)
  .map(&:strip)
  .reject(&:empty?)

missing_files = ordered_files.reject { |name| File.file?(File.join(ASSETS_DIR, name)) }
abort("Missing files in assets/order.txt:\n#{missing_files.join("\n")}") unless missing_files.empty?

FileUtils.mkdir_p(LARGE_DIR)
FileUtils.mkdir_p(THUMB_DIR)

Dir.glob(File.join(LARGE_DIR, "gallery-*.jpg")).each { |path| FileUtils.rm_f(path) }
Dir.glob(File.join(THUMB_DIR, "gallery-*.jpg")).each { |path| FileUtils.rm_f(path) }

ordered_files.each_with_index do |name, index|
  number = format("%03d", index + 1)
  source = File.join(ASSETS_DIR, name)
  run_sips("-s", "format", "jpeg", "-Z", "1600", source, "--out", File.join(LARGE_DIR, "gallery-#{number}.jpg"))
  run_sips("-s", "format", "jpeg", "-Z", "320", source, "--out", File.join(THUMB_DIR, "gallery-#{number}.jpg"))
end

manifest_items = gallery_items(ordered_files.length, quoted_keys: true)
manifest = "globalThis.galleryImages = [\n" +
  manifest_items.map { |item| item.lines.map { |line| "  #{line}" }.join }.join(",\n") +
  "\n];\n"
File.write(MANIFEST_FILE, manifest)

script_items = gallery_items(ordered_files.length, quoted_keys: false)
script_replacement = "  gallery: globalThis.galleryImages || [\n" +
  script_items.map { |item| item.lines.map { |line| "    #{line}" }.join }.join(",\n") +
  "\n  ],\n  music:"
script = File.read(SCRIPT_FILE)
gallery_pattern = /  gallery: globalThis\.galleryImages \|\| \[\n.*?\n  \],\n  music:/m
abort("Could not find gallery fallback block in script.js") unless script.match?(gallery_pattern)
File.write(SCRIPT_FILE, script.sub(gallery_pattern, script_replacement))

index = File.read(INDEX_FILE)
index = index
  .gsub(/assets\/gallery-manifest\.js\?v=[^"]+/, "assets/gallery-manifest.js?v=#{VERSION}")
  .gsub(/script\.js\?v=[^"]+/, "script.js?v=#{VERSION}")
  .gsub(/assets\/gallery-large\/gallery-001\.jpg\?v=[^"]+/, "assets/gallery-large/gallery-001.jpg?v=#{VERSION}")
  .gsub(/data-gallery-progress>1 \/ \d+</, "data-gallery-progress>1 / #{ordered_files.length}<")
File.write(INDEX_FILE, index)

puts "Built #{ordered_files.length} gallery images from assets/order.txt"
