# Graph class for pull_articles.rb

class Graph
  def initialize
    @@id_title_hash = {}
    @@relationship_hash = {}
    @@articles = $articles_g
    @@sections = $sections_g
    @@categories = $categories_g

    $LOAD_PATH.unshift('../lib')
    @@g = GraphViz.new('G')

    @@g.node[:color] = '#222222'
    @@g.node[:style] = 'filled'
    @@g.node[:shape] = 'box'
    @@g.node[:penwidth] = '1'
    @@g.node[:fontname] = 'Helvetica'
    @@g.node[:fillcolor] = '#eeeeee'
    @@g.node[:fontcolor] = '#333333'
    @@g.node[:margin] = '0.05'
    @@g.node[:fontsize] = '12'
    @@g.edge[:color] = '#666666'
    @@g.edge[:weight] = '1'
    @@g.edge[:fontsize] = '10'
    @@g.edge[:fontcolor] = '#444444'
    @@g.edge[:fontname] = 'Helvetica'
    @@g.edge[:dir] = 'forward'
    @@g.edge[:arrowsize] = '1'
    @@g.edge[:arrowhead] = 'vee'
  end

  def self.wrap(s, width = 20)
    s.gsub(/(.{1,#{width}})(\s+|\Z)/, "\\1\n")
  end

  def self.create_id_title_relationship
    @@articles.each do |article|
      @@id_title_hash[article['id']] = article['title']
    end
  end

  def self.extract_links(string)
    [URI.extract(string, /http(s)?/)].flatten
  end

  def self.extract_IDs(string)
    string.split(//).map { |x| x[/\d+/] }.compact.join('').to_i
  end

  def self.relationship_hash
    r = {}
    @@articles.each do |article|
      unless (@@categories[@@sections[article['section_id']]['category_id']]['name'] == 'Announcements') || (article['body'].class != String)
        referenced_links = extract_links(article['body'])

        referenced_articles = []
        unless referenced_links.empty?
          referenced_links.each do |link|
            id = extract_IDs(link)
            title = @@id_title_hash[id]
            unless (id.class == NilClass) || (title.class == NilClass) || (id.to_s.size != 9)
              referenced_articles << wrap("#{title}\n#{id}")
            end
          end
          r[article['id']] = referenced_articles
        end
        @@relationship_hash = r
      end
    end
  end

  def self.graph_nodes
    nodes = []
    @@relationship_hash.each do |id, _referenced_articles|
      nodes << wrap("#{@@id_title_hash[id]}\n#{id}")
    end
    @@g.add_nodes(nodes)
  end

  def self.graph_edges
    @@relationship_hash.each do |id, referenced_articles|
      @@g.add_edges(wrap("#{@@id_title_hash[id]}\n#{id}"), referenced_articles.map(&:to_s))
    end
  end

  def generate
    self.class.create_id_title_relationship
    self.class.relationship_hash
    self.class.create_id_title_relationship
    self.class.graph_nodes
    self.class.graph_edges
    @@g.output(png: "#{$PROGRAM_NAME}.png")
  end
end
