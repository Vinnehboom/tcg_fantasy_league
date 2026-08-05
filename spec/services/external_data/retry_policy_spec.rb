require 'rails_helper'

module ExternalData

  RSpec.describe RetryPolicy do
    describe '#timeout' do
      context 'when no timeout is given' do
        subject(:policy) { described_class.new }

        it 'defaults to 10 seconds' do
          expect(policy.timeout).to eq(10)
        end
      end

      context 'when a timeout is given' do
        subject(:policy) { described_class.new(timeout: 3) }

        it 'uses the given timeout' do
          expect(policy.timeout).to eq(3)
        end
      end
    end

    describe '#max_attempts' do
      context 'when no retry_delays are given' do
        subject(:policy) { described_class.new }

        it 'defaults to one initial attempt plus two retries' do
          expect(policy.max_attempts).to eq(3)
        end
      end

      context 'when retry_delays are given' do
        subject(:policy) { described_class.new(retry_delays: [0, 0, 0]) }

        it 'is one more than the number of retry delays' do
          expect(policy.max_attempts).to eq(4)
        end
      end
    end

    describe '#delay_before_retry' do
      subject(:policy) { described_class.new(retry_delays: [0.5, 1.0]) }

      context 'when no retry_after is given' do
        it 'falls back to the backoff schedule for that attempt' do
          expect(policy.delay_before_retry(attempt: 2)).to eq(1.0)
        end
      end

      context 'when retry_after is numeric and under the cap' do
        it 'uses the retry_after value' do
          expect(policy.delay_before_retry(attempt: 1, retry_after: 5)).to eq(5)
        end
      end

      context 'when retry_after is numeric and over the cap' do
        it 'caps the delay at max_retry_after' do
          expect(policy.delay_before_retry(attempt: 1, retry_after: 120)).to eq(30)
        end
      end

      context 'when retry_after is non-numeric' do
        it 'falls back to the backoff schedule for that attempt' do
          expect(policy.delay_before_retry(attempt: 1, retry_after: 'later')).to eq(0.5)
        end
      end

      context 'when retry_after is nil' do
        it 'falls back to the backoff schedule for that attempt' do
          expect(policy.delay_before_retry(attempt: 1, retry_after: nil)).to eq(0.5)
        end
      end
    end
  end

end
