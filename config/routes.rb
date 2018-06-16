resources :gtt_print_jobs, only: %i(create show) do
  member do
    get :status
  end
end
