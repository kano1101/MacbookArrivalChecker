# coding: utf-8
class AppleBrowser
  LOGIN_URL = 'https://secure4.store.apple.com/jp/shop/signIn?c=aHR0cHM6Ly93d3cuYXBwbGUuY29tL2pwL3wxYW9zMTYwYTVlOTk4NzNmOTkxZjU2ZmIyYTc5YjcyMTk3OWY2YWE2MjljOQ&r=SCDHYHP7CY4H9XK2H&s=aHR0cHM6Ly93d3cuYXBwbGUuY29tL2pwL3wxYW9zMTYwYTVlOTk4NzNmOTkxZjU2ZmIyYTc5YjcyMTk3OWY2YWE2MjljOQ'
  BAG_URL = 'https://www.apple.com/jp/shop/bag'
  WANTED_URL = 'https://www.apple.com/jp/shop/product/G11C3J/A/' # 書いたい Macbook Pro
#  WANTED_URL = 'https://www.apple.com/jp/shop/product/FGN63J/A/' # Macbook Air
  URLS = [
    "https://www.apple.com/jp/shop/product/G11C3J/A/",
    "https://www.apple.com/jp/shop/product/G11F3J/A/",
    "https://www.apple.com/jp/shop/product/G11C2J/A/",
    "https://www.apple.com/jp/shop/product/G11F2J/A/",
#    "https://www.apple.com/jp/shop/product/FGN63J/A/", # Macbook Air
  ].freeze

  def self.login
    browser = Watir::Browser.new :chrome
    browser.goto(LOGIN_URL)

    browser.text_field(id: 'signIn.customerLogin.appleId').set(ENV['EMAIL'])
    browser.text_field(id: 'signIn.customerLogin.password').set(ENV['PASSWORD'])
    
    browser.element(id: 'signin-submit-button').click
    browser.wait_while(timeout: 60) { |b| b.button(id: 'signin-submit-button').present? }
    browser
  end
  
  def self.scrape(browser)
    URLS.map do |url|
      browser.goto(url)
      browser.wait

      existence_check_div = browser.div(class: 'rf-dude-quote-info')
      
      is_exists_word = existence_check_div.text.include?('在庫切れ') ? 'なし' : nil
      is_exists_word ||= existence_check_div.text.include?('送料無料') ? 'あり' : '不明'

      title = browser.title[/MacBook \w{3}/]
      price = browser.div(class: "rf-pdp-price").text
      color = browser.title[/チップ - (.+) - Apple（日本）/, 1]
      d = browser.div(class: "Overview-panel") 
      memory_size = d.html[/\s(\w+)ユニファイドメモリ/, 1]
      storage_size = d.html[/\s(\w+) SSD/, 1]
      
      "在庫#{is_exists_word} : メモリ#{memory_size.rjust(4)}, ストレージ#{storage_size.rjust(5)} : #{title} : #{color} : #{price} : #{url}"
    end
  end

  def self.add_to_the_bag_if_not_yet(browser, url)
    browser.goto(BAG_URL)
    if browser.html.include?('注文手続きへ')
      LineNotify.send('すでにバッグにアイテムが追加されています。')
    else
      browser.goto(url)
      browser.wait
      button = browser.button(id: 'add-to-cart')
      if button.enabled?
        button.click
        browser.wait
        LineNotify.send('バッグにアイテムを追加しました。')
      end
    end
  end

  def self.run
    browser = self.login
    messages = self.scrape(browser)

    result_messages = messages.select do |message|
      !message.include?('なし')
    end
    result_messages.each do |message|
      LineNotify.send(message)
    end
    # if result_messages.count == 0
    #   LineNotify.send('在庫なし')
    # end

    self.add_to_the_bag_if_not_yet(browser, WANTED_URL)
    browser.close
  end
end
