class Posts::ShowPresenter
  attr_reader :controller, :post
  
  extend ActiveModel::Naming
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::DateHelper
  include Rails.application.routes.url_helpers
  
  def initialize(post)
    @post = post
  end
  
  def cache_key
    "post:#{post.id}"
  end
  
  def preview
    @preview ||= begin
      raw = Replaceable.new(post.preview)
      raw.replace_tags!.replace_usernames!
      raw.body.html_safe
    end
  end
  
  def body
    @body ||= (Markdown.markdown begin
      raw = Replaceable.new(post.body)
      # IMPORTANT
      # replace_gists use CGI::escapeHTML, so it should be called first
      # letting tags and usernames been replaced with links properly
      raw.replace_gists!.replace_tags!.replace_usernames!
      raw.body.html_safe
    end)
  end
  
  def title
    u = link_to user.username, user_path(:id => user.username), :class => 'username'
    t = link_to type, type_path
    w = time_ago_in_words(post.created_at)
    
    @post.title || "#{u} wrote in #{t} #{w} ago".html_safe
  end
  
  def user
    post.user
  end
  
  def type
    post.type.split('::').last.downcase
  end
  
  def likes_count
    post.likes_count
  end
  
  def comments_count
    post.comments_count
  end
  
  def comments
    post.comments.to_a.select(&:persisted?)
  end
  
protected

  def type_path
    case post.class.to_s
    when 'Post::Article' then
      post_articles_path
    when 'Post::Question' then
      post_questions_path
    when 'Post::Gossip' then
      post_gossips_path
    end
  end
end