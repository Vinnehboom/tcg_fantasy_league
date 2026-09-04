# Per-game composition root for +Game+. Each known game — PTCG today, more
# later — registers itself once: its id, a +Game.<name>+ finder scope, and
# whatever per-game collaborators it needs (currently its adapter, its
# results verifier, and its results-import job class). Callers ask a +Game+
# instance for its own collaborator — `tournament.game.adapter`,
# `tournament.game.results_verifier`, `tournament.game.results_import_job`
# — instead of switching on its id, so onboarding a new game means one
# +register+ call here, not a new branch in a shared conditional elsewhere
# in the app.
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

  # Wrapped the same way as #results_verifier below (H-9 round 2): a
  # configured adapter_builder lambda receives the registered adapter as a
  # lazy block, so an environment can swap in a different one — currently
  # only development does, to avoid a real HTTP call from every import job.
  # A game with no registered adapter (Riftbound today) yields nil here,
  # same as an unregistered results_verifier: honestly unavailable, not a
  # branch anywhere that picks a stand-in for it.
  def adapter
    adapter_builder.call(game: self) { registered_adapter }
  end

  # A configured verifier_builder lambda receives the registered verifier as
  # a lazy block, so an environment can swap in a different one — currently
  # only development does, to avoid a real HTTP call from the admin
  # "verify tournament id" flow. results_import_job stays a direct reader:
  # it names a job class, not an HTTP call, so there is nothing to stand in
  # for.
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
    self.class.registrations.dig(id, :adapter)&.call(game: self)
  end

  def verifier_builder
    Rails.application.config.x.external_data.verifier_builder
  end

  def registered_verifier
    self.class.registrations.dig(id, :results_verifier)
  end

end
