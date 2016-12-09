# Zendesk class for pull_articles.rb

class ZendeskArticle
  def initialize
    @root_uri = $zendesk_url
    @articles_uri = @root_uri + 'articles.json'
    @sections_uri = @root_uri + 'sections.json'
    @categories_uri = @root_uri + 'categories.json'
    check_auth
  end

  def articles
    @articles ||= begin
      progressbar = ProgressBar.create(title: "#{raw_articles['count']} Articles", starting_at: 1, format: '%a |%b>>%i| %p%% %t', total: raw_articles['page_count'])
      articles = raw_articles['articles']

      (raw_articles['page_count'] - 1).times do |page|
        progressbar.increment
        articles += HTTParty.get("#{@articles_uri}?page=#{page + 2}", basic_auth)['articles']
      end
    end
    articles
  end

  def sections
    @sections ||= begin
      progressbar = ProgressBar.create(title: "#{raw_sections['count']} Sections", starting_at: 1, format: '%a |%b>>%i| %p%% %t', total: raw_sections['page_count'])
      sections = raw_sections['sections']

      (raw_sections['page_count'] - 1).times do |page|
        progressbar.increment
        sections += HTTParty.get("#{@sections_uri}?page=#{page + 2}", basic_auth)['sections']
      end
    end
    sections
  end

  def categories
    @categories ||= begin
      progressbar = ProgressBar.create(title: "#{raw_categories['count']} Categories", starting_at: 1, format: '%a |%b>>%i| %p%% %t', total: raw_categories['page_count'])
      categories = raw_categories['categories']

      (raw_categories['page_count'] - 1).times do |page|
        progressbar.increment
        categories += HTTParty.get("#{@categories_uri}?page=#{page + 2}", basic_auth)['categories']
      end
    end
    categories
  end

  def raw_articles
    @raw_articles ||= HTTParty.get(@articles_uri, basic_auth)
  end

  def raw_sections
    @raw_sections ||= HTTParty.get(@sections_uri, basic_auth)
  end

  def raw_categories
    @raw_sections ||= HTTParty.get(@categories_uri, basic_auth)
  end

  def export_columns
    %w(id category section title word_count draft promoted outdated html_url created_at updated_at)
  end

  def basic_auth
    {
      basic_auth: {
        username: $zendesk_username,
        password: $zendesk_password,
      },
    }
  end

  def check_auth
    response = HTTParty.get(@sections_uri, basic_auth)
    unless response.code == 200
      puts "Error #{response.code}: #{response.message}"
      abort
    end
  end
end
