module Demo

  # Shared by every Demo:: entry point that can write to the database
  # (H-9 review round 1, B2): Demo::Seeder, Demo::History and
  # Demo::DraftSeeder each raise on production independently, on top of the
  # synthetic adapter's own guard, so a demo-dataset write is refused before
  # the first row is written, not partway through. A plain RuntimeError, not
  # ExternalData::Exception: this is a Demo:: concern, not an ExternalData
  # one.
  module ProductionGuard

    def raise_outside_the_sandbox!
      return unless Rails.env.production?

      raise "#{self.class.name} must never run against the production database"
    end

  end

end
