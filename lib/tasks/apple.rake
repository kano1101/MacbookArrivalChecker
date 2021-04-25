# coding: utf-8
namespace :apple do
  desc "Apple Storeに欲しい商品が追加されたら通知するタスク"
  task store: :environment do
    AppleBrowser::run
  end
end
