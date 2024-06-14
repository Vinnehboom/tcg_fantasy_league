module ExternalData

  module Pokemon

    module Tcg

      class Tournaments < Scraper

        def self.upcoming_tournaments
          tournament_page = get('/tournaments/upcoming',
                                query: { region: 'all', time: 'all', game_format: 'all', show: 100, page: 1 })
          parse_tournaments(tournament_page)
        end

        def self.parse_tournaments(html_content)
          tournaments = []
          content = Nokogiri.HTML5(html_content)
          table_rows = content.search('tr')
          table_rows.each do |table_row|
            cells = table_row.search('td')
            next if cells.blank?

            tournaments = parse_row(cells, tournaments)
          end
          tournaments
        end

        def self.parse_row(cells, tournaments) # rubocop:disable Metrics/AbcSize
          tournament = Tournament.new
          return tournaments unless cells[4].children[0].text

          tournament.starting_date = cells[0].content.to_date + 2000.years
          tournament.country = cells[1].element_children[0].attribute_nodes[2].value
          name_cell = cells[2]
          tournament.name = name_cell.content
          tournament.external_id = name_cell.element_children[0].attribute_nodes[0].value
          tournament.format = cells[3].element_children[0].attribute_nodes[2].value

          tournaments << tournament
          tournaments
        end

      end

    end

  end

end
