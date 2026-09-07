module CountriesHelper

  COUNTRY_OPTIONS = ISO3166::Country.codes
                                    .map { |code| [ISO3166::Country.new(code).common_name, code] }
                                    .sort_by(&:first)
                                    .freeze

  def country_options
    COUNTRY_OPTIONS
  end

end
