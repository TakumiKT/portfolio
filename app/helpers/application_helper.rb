module ApplicationHelper
  def ogp_image_url
    # app/assets/images/ogp.png を使う前提
    image_url("ogp.png")
  end
end
