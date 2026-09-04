# Per-game composition root for +Game+: registers each game's id, its
# +Game.<name>+ finder scope, and its adapter/results_verifier/
# results_import_job collaborators.
module GameRegistry

  extend ActiveSupport::Concern

  class_methods do
    def register(scope_name, id:, adapter: nil, results_verifier: nil, results_import_job: nil)
      define_singleton_method(scope_name) { find_by(id:) }
      registrations[id] = { adapter:, results_verifier:, results_import_job: }
    end

    def registrations
      @registrations ||= {}
    end
  end

  # In development, adapter_builder ignores this block and returns a
  # synthetic adapter for every game — see AdapterBuilder.
  def adapter
    adapter_builder.call(game: self) { registered_adapter }
  end

  def results_verifier
    verifier_builder.call(game: self) { registered_verifier }
  end

  def results_import_job
    self.class.registrations.dig(id, :results_import_job)
  end

  private

  def adapter_builder
    Rails.application.config.x.external_data.adapter_builder
  end

  def registered_adapter
    self.class.registrations.dig(id, :adapter)&.call(game: self) || ExternalData::OfflineAdapter.new
  end

  def verifier_builder
    Rails.application.config.x.external_data.verifier_builder
  end

  def registered_verifier
    self.class.registrations.dig(id, :results_verifier)
  end

end
