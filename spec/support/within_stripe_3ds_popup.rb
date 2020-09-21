def within_stripe_3ds_popup
  using_wait_time(10) do
    within_frame 0 do
      within_frame 0 do
        expect(page).to have_text('3D Secure 2 Test Page', normalize_ws: true)
        yield
      end
    end
  end
end
