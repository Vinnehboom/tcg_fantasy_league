module ExternalData

  module Pokemon

    module Tcg

      class Players

        include HTTParty
        base_uri 'https://limitlesstcg.com'

        def self.all
          player_pages = get_all_pages
          parse_players(player_pages)
        end

        def self.get_all_pages(pages: '', page: 1)
          page_html = get('/players', query: { region: 'all', time: 'all', game_format: 'all', show: 100, page: })
          page_content = Nokogiri.HTML5(page_html).search('table')
          if players_present(page_content)
            pages += page_html
            get_all_pages(pages:, page: page + 1)
          else
            pages
          end
        end

        def self.parse_players(html_content)
          players = []
          content = Nokogiri.HTML5(html_content)
          player_table_rows = content.search('tr')
          player_table_rows.each do |table_row|
            cells = table_row.search('td')
            next if cells.blank?

            players << parse_row(cells)
          end
          players
        end

        def self.players_present(html_content)
          table_cells = html_content.search('td')
          table_cells.present?
        end

        def self.parse_row(cells)
          player = {}
          return unless cells[4].children[0]&.text

          name_cell = cells[1]
          player['name'] = name_cell.content
          player['external_id'] = name_cell.element_children[0].attribute_nodes[0].value
          player['country'] = cells[3].element_children[0].attribute_nodes[2].value
          player['external_points'] = cells[4].children[0].text
          player
        end

      end

    end

  end

end
