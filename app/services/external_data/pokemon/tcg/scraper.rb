module ExternalData

  module Pokemon

    module Tcg

      class Scraper

        include HTTParty
        base_uri 'https://limitlesstcg.com'

        def self.get_all_pages(path, pages: '', page: 1)
          page_html = get(path, query: { region: 'all', time: 'all', type: 'all', format: 'all', show: 100, page: })
          page_content = Nokogiri.HTML5(page_html).search('table')
          if table_content?(page_content)
            pages += page_html
            get_all_pages(path, pages:, page: page + 1)
          else
            pages
          end
        end

        def self.table_content?(html_content)
          table_cells = html_content.search('td')
          table_cells.present?
        end

      end

    end

  end

end
