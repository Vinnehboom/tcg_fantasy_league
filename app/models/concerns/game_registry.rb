# Per-game composition root for +Game+. Each known game — PTCG today, more
# later — registers itself once: its id, a +Game.<name>+ finder scope, and
# whatever per-game collaborators it needs (currently just its results
# verifier). Callers ask a +Game+ instance for its own collaborator —
# `tournament.game.results_verifier` — instead of switching on its id, so
# onboarding a new game means one +register+ call here, not a new branch in
# a shared conditional elsewhere in the app.
module GameRegistry

  extend ActiveSupport::Concern

  class_methods do
    def register(scope_name, id:, results_verifier: nil)
      define_singleton_method(scope_name) { find_by(id:) }
      registrations[id] = { results_verifier: }
    end

    def registrations
      @registrations ||= {}
    end
  end

  def results_verifier
    self.class.registrations.dig(id, :results_verifier)
  end

end
