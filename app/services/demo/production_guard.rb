module Demo

  module ProductionGuard

    def raise_outside_the_sandbox!
      return unless Rails.env.production?

      raise "#{self.class.name} must never run against the production database"
    end

  end

end
