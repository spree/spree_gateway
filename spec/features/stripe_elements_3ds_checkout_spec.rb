# frozen_string_literal: true

require 'spec_helper'

describe 'Stripe Elements 3ds checkout', type: :feature, js: true do
  let!(:product) { create(:product, name: 'RoR Mug') }
  let!(:stripe_payment_method) do
    Spree::Gateway::StripeElementsGateway.create!(
      name: 'Stripe',
      preferred_secret_key: 'sk_test_VCZnDv3GLU15TRvn8i2EsaAN',
      preferred_publishable_key: 'pk_test_Cuf0PNtiAkkMpTVC2gwYDMIg',
      preferred_intents: preferred_intents
    )
  end

  describe 'when one StripeElementsGateway payment methods is defined' do
    before do
      user = create(:user)
      order = OrderWalkthrough.up_to(:confirm)
      expect(order).to receive(:confirmation_required?).and_return(true).at_least(:once)

      order.reload
      order.user = user
      payment = order.payments.first
      payment.source = create(:credit_card, number: card_number)
      payment.save!

      allow_any_instance_of(Spree::CheckoutController).to receive_messages(current_order: order)
      allow_any_instance_of(Spree::CheckoutController).to receive_messages(try_spree_current_user: user)
      allow_any_instance_of(Spree::CheckoutController).to receive_messages(skip_state_validation?: true)
      allow_any_instance_of(Spree::OrdersController).to receive_messages(try_spree_current_user: user)

      add_to_cart(product)
      click_link 'checkout'
      click_button 'Place Order'
    end

    describe 'when intents are disabled' do
      let(:preferred_intents) { false }

      context 'and credit card does not require 3ds authentication' do
        let(:card_number) { '4242424242424242' }

        it 'should place order without 3ds authentication' do
          expect(page).to have_content('Order placed successfully')
          order = Spree::Order.complete.last
          expect(page.current_url).to include("/orders/#{order.number}")
          expect(page).to have_content(order.number)
        end
      end

      context 'and credit card does require 3ds authentication' do
        let(:card_number) { '4000000000003220' }

        it 'should not place the order' do
          expect(page).to have_content('Your card was declined. This transaction requires authentication.')
          expect(Spree::Order.complete.last).to be_nil
        end
      end
    end

    describe 'when intents are enabled' do
      let(:preferred_intents) { true }

      context 'and credit card does not require 3ds authentication' do
        let(:card_number) { '4242424242424242' }

        it 'should successfully place order without 3ds authentication' do
          expect(page).to have_content('Order placed successfully')
          order = Spree::Order.complete.last
          expect(page.current_url).to include("/orders/#{order.number}")
          expect(page).to have_content(order.number)
        end
      end

      context 'when credit card does require 3ds authentication' do
        let(:card_number) { '4000000000003220' }

        context 'and authentication is successful' do
          it 'should place order after 3ds authentication' do
            within_stripe_3ds_popup do
              click_button('Complete')
            end

            expect(page).to have_content('Order placed successfully')
            order = Spree::Order.complete.last
            expect(page.current_url).to include("/orders/#{order.number}")
            expect(page).to have_content(order.number)
          end
        end

        context 'and authentication is unsuccessful' do
          it 'should not place order after 3ds authentication' do
            within_stripe_3ds_popup do
              click_button('Fail')
            end

            expect(page).to_not have_content('Order placed successfully')
            expect(page).to have_content('We are unable to authenticate your payment method.')
            expect(page).to have_content('Please choose a different payment method and try again.')
            expect(Spree::Order.complete.last).to be_nil
          end
        end
      end
    end
  end

  describe 'when two StripeElementsGateway payment methods are defined' do
    before do
      Spree::Gateway::StripeElementsGateway.create!(
        name: 'Stripe2',
        preferred_secret_key: 'sk_test_VCZnDv3GLU15TRvn8i2EsaAN',
        preferred_publishable_key: 'pk_test_Cuf0PNtiAkkMpTVC2gwYDMIg',
        preferred_intents: preferred_intents
      )
    end

    context 'on payment_methods step' do
      let(:preferred_intents) { true }

      before do
        user = create(:user)
        order = OrderWalkthrough.up_to(:payment)
        order.user = user

        allow_any_instance_of(Spree::CheckoutController).to receive_messages(current_order: order)
        allow_any_instance_of(Spree::CheckoutController).to receive_messages(try_spree_current_user: user)

        add_to_cart(product)
        click_link 'checkout'

        visit spree.checkout_state_path(:payment)
      end

      it 'should allow to choose every payment method' do
        expect(page).to have_selector('#payment_method_1', visible: true)
        within('#payment_method_1') do
          expect(page).to have_selector('#name_on_card_1', visible: true)
          expect(page).to have_selector('#card-element-1', visible: true)
        end
        expect(page).to have_selector('#payment_method_2', visible: false)

        within('#payment-method-fields') do
          find('label', text: 'Stripe2').click
        end

        expect(page).to have_selector('#payment_method_1', visible: false)
        expect(page).to have_selector('#payment_method_2', visible: true)
        within('#payment_method_2') do
          expect(page).to have_selector('#name_on_card_2', visible: true)
          expect(page).to have_selector('#card-element-2', visible: true)
        end
      end
    end
  end
end
