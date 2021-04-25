# coding: utf-8
#require 'headless'
class AppleBrowser
  URLS = [
    "https://www.apple.com/jp/shop/product/G11C3J/A/",
    "https://www.apple.com/jp/shop/product/G11F3J/A/",
    "https://www.apple.com/jp/shop/product/G11C2J/A/",
    "https://www.apple.com/jp/shop/product/G11F2J/A/",
 #   "https://www.apple.com/jp/shop/product/FGN63J/A/",
  ].freeze
  def self.run
    headless = Headless.new
    headless.start
    browser = Watir::Browser.new :phantomjs
    messages = URLS.map do |url|
      browser.goto(url)
      is_exists_word = browser.html.include?('在庫切れ') ? 'なし' : 'あり'
      title = browser.title[/MacBook \w{3}/]
      price = browser.div(class: "rf-pdp-price").text
      color = browser.title[/チップ - (.+) - Apple（日本）/, 1]
      d = browser.div(class: ["rc-pdsection-panel", "Overview-panel"]) 
      memory_size = d.html[/\s(\w+)ユニファイドメモリ/, 1]
      storage_size = d.html[/\s(\w+) SSD/, 1]
      "在庫#{is_exists_word} : メモリ#{memory_size.rjust(4)}, ストレージ#{storage_size.rjust(5)} : #{title} : #{color} : #{price}"
    end
    browser.close
    headless.destroy
    p 'チェック終了'

    result_messages = messages.select do |message|
      message.include?('あり')
    end

    result_messages.each do |message|
      LineNotify.send(message)
    end
  end
end
