# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2026_05_19_062545) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "cube"
  enable_extension "earthdistance"
  enable_extension "plpgsql"

  create_table "active_admin_comments", force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_type"
    t.bigint "resource_id"
    t.string "author_type"
    t.bigint "author_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id"
  end

  create_table "admin_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "app_subscriptions_invoice_items", force: :cascade do |t|
    t.bigint "app_subscriptions_invoice_id"
    t.string "item_name"
    t.datetime "start_date"
    t.datetime "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "amount"
    t.jsonb "billable_details"
    t.index ["app_subscriptions_invoice_id"], name: "idx_app_sub_inv_itms_app_sub_invs"
  end

  create_table "app_subscriptions_invoices", force: :cascade do |t|
    t.bigint "restaurant_id"
    t.bigint "app_subscriptions_restaurant_plan_id"
    t.datetime "start_date"
    t.datetime "end_date"
    t.integer "amount"
    t.string "payment_status", default: "not_paid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "invoice_date"
    t.datetime "due_date"
    t.integer "app_subscriptions_subscription_id"
    t.integer "invoice_number"
    t.index ["app_subscriptions_restaurant_plan_id"], name: "idx_app_sub_invs_app_sub_res_plan"
    t.index ["invoice_number"], name: "index_app_subscriptions_invoices_on_invoice_number", unique: true
    t.index ["restaurant_id"], name: "index_app_subscriptions_invoices_on_restaurant_id"
  end

  create_table "app_subscriptions_payment_provider_orders", force: :cascade do |t|
    t.string "payment_provider"
    t.string "payment_provider_reference_id"
    t.string "payment_status"
    t.string "orderable_type"
    t.bigint "orderable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["orderable_type", "orderable_id"], name: "idx_app_sub_pymnt_prvdr_ords_orderable_type_orderable_id"
  end

  create_table "app_subscriptions_payment_provider_payments", force: :cascade do |t|
    t.json "payment_provider_params"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "app_subscriptions_plans", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.string "discount_label"
    t.boolean "active", default: true
    t.integer "plan_duration"
    t.integer "unit_price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "premium_unit_price", precision: 8, scale: 2
  end

  create_table "app_subscriptions_restaurant_plans", force: :cascade do |t|
    t.bigint "app_subscriptions_plan_id"
    t.bigint "restaurant_id"
    t.datetime "start_date"
    t.datetime "end_date"
    t.string "status", default: "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["app_subscriptions_plan_id"], name: "idx_app_sub_res_plan_app_sub_plan"
    t.index ["restaurant_id"], name: "idx_app_sub_res_plan_restaurant"
  end

  create_table "app_subscriptions_subscriptions", force: :cascade do |t|
    t.integer "app_subscriptions_plan_id"
    t.string "subscriber_type"
    t.integer "subscriber_id"
    t.datetime "start_date"
    t.datetime "end_date"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "apps", force: :cascade do |t|
    t.string "name"
    t.string "logo_url"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "team_roles", default: [], array: true
    t.string "identifier"
    t.boolean "allowed_to_subscribe"
    t.index ["identifier"], name: "index_apps_on_identifier"
  end

  create_table "bank_details", force: :cascade do |t|
    t.string "account_number"
    t.string "account_holder_name"
    t.string "ifsc_code"
    t.string "string"
    t.bigint "restaurant_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["restaurant_id"], name: "index_bank_details_on_restaurant_id"
  end

  create_table "businesses", force: :cascade do |t|
    t.string "name", default: "", null: false
    t.string "business_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "country"
    t.text "device_preference", default: [], array: true
    t.string "referral_code"
  end

  create_table "channel_integrations", force: :cascade do |t|
    t.datetime "start_at"
    t.datetime "end_at"
    t.string "channel"
    t.bigint "restaurant_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["restaurant_id"], name: "index_channel_integrations_on_restaurant_id"
  end

  create_table "channels", force: :cascade do |t|
    t.string "name"
    t.integer "restaurant_id"
    t.boolean "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_channels_on_name"
  end

  create_table "combo_items", force: :cascade do |t|
    t.bigint "combo_id"
    t.string "comboable_type"
    t.bigint "comboable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "quantity"
    t.datetime "deleted_at"
    t.index ["combo_id"], name: "index_combo_items_on_combo_id"
    t.index ["comboable_type", "comboable_id"], name: "index_combo_items_on_comboable_type_and_comboable_id"
    t.index ["deleted_at"], name: "index_combo_items_on_deleted_at"
  end

  create_table "combos", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.integer "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "restaurant_id"
    t.boolean "is_active", default: false
    t.boolean "is_recommended", default: false
    t.string "image_url"
    t.boolean "is_sold_at_store", default: false
    t.boolean "pending_availability_sync", default: false
    t.boolean "pending_catalogue_sync", default: true
    t.integer "tax_ids", default: [], array: true
    t.string "channels", default: [], array: true
    t.integer "packaging_charge"
    t.datetime "deleted_at"
    t.bigint "location_id"
    t.integer "restaurant_ids", default: [], array: true
    t.boolean "tax_exempted"
    t.string "tax_not_required_reason"
    t.string "pet_pooja_ref_id"
    t.string "pet_pooja_taxes", default: [], array: true
    t.index ["deleted_at"], name: "index_combos_on_deleted_at"
    t.index ["location_id"], name: "index_combos_on_location_id"
    t.index ["pet_pooja_ref_id"], name: "index_combos_on_pet_pooja_ref_id"
    t.index ["restaurant_id"], name: "index_combos_on_restaurant_id"
  end

  create_table "cuisines", force: :cascade do |t|
    t.string "name"
    t.string "image"
    t.text "description"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "cuisines_restaurants", id: false, force: :cascade do |t|
    t.bigint "restaurant_id", null: false
    t.bigint "cuisine_id", null: false
    t.index ["cuisine_id"], name: "index_cuisines_restaurants_on_cuisine_id"
    t.index ["restaurant_id"], name: "index_cuisines_restaurants_on_restaurant_id"
  end

  create_table "currencies", force: :cascade do |t|
    t.string "name", null: false
    t.string "code", null: false
    t.string "symbol"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["code"], name: "index_currencies_on_code", unique: true
  end

  create_table "day_audits", force: :cascade do |t|
    t.string "unique_reference"
    t.float "amount_received"
    t.float "difference"
    t.text "remarks"
    t.integer "status", default: 0
    t.datetime "completed_at"
    t.string "auditor_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "restaurant_id"
    t.bigint "user_id"
    t.bigint "team_member_id"
    t.json "total_split", default: {}
    t.json "received_split", default: {}
    t.date "orders_date"
    t.index ["completed_at"], name: "index_day_audits_on_completed_at"
    t.index ["orders_date"], name: "index_day_audits_on_orders_date"
    t.index ["restaurant_id"], name: "index_day_audits_on_restaurant_id"
    t.index ["status"], name: "index_day_audits_on_status"
    t.index ["team_member_id"], name: "index_day_audits_on_team_member_id"
    t.index ["unique_reference"], name: "index_day_audits_on_unique_reference"
    t.index ["user_id"], name: "index_day_audits_on_user_id"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
    t.index ["queue"], name: "delayed_jobs_queue"
  end

  create_table "delivery_addresses", force: :cascade do |t|
    t.string "mobile_number"
    t.text "address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.bigint "restaurant_id"
    t.index ["mobile_number", "address", "restaurant_id"], name: "index_delivery_addresses", unique: true
    t.index ["mobile_number"], name: "index_delivery_addresses_on_mobile_number"
    t.index ["restaurant_id"], name: "index_delivery_addresses_on_restaurant_id"
    t.index ["user_id"], name: "index_delivery_addresses_on_user_id"
  end

  create_table "delivery_configurations", force: :cascade do |t|
    t.string "delivery_partner", default: "own_delivery"
    t.float "delivery_charge", default: 0.0
    t.float "delivery_charge_from", default: 0.0
    t.float "free_delivery_order_value", default: 0.0
    t.float "delivery_flat_charge", default: 0.0
    t.float "minimum_order_value", default: 0.0
    t.float "delivery_radius"
    t.jsonb "delivery_type", default: ["takeaway"]
    t.string "paid_by", default: "customer"
    t.jsonb "charge_breakdown", default: {"customer"=>100, "restaurant"=>0}
    t.bigint "restaurant_platform_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "assignment_delay_type", default: "immediate"
    t.integer "assignment_delay_minutes", default: 0
    t.index ["restaurant_platform_id"], name: "index_delivery_configurations_on_restaurant_platform_id"
  end

  create_table "demo_requests", force: :cascade do |t|
    t.string "restaurant"
    t.string "contact_number"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contact_number"], name: "index_demo_requests_on_contact_number"
  end

  create_table "details_order_items", force: :cascade do |t|
    t.string "name"
    t.integer "quantity"
    t.float "unit_price"
    t.float "total_price_with_tax"
    t.float "unit_weight"
    t.integer "partner_item_id"
    t.integer "zomato_item_id"
    t.integer "zomato_item_group_id"
    t.integer "zomato_item_addon_group_id"
    t.integer "zomato_item_variant_id"
    t.integer "zomato_item_group_choice_id"
    t.integer "zomato_item_addon_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "order_id"
    t.float "total"
    t.json "options_to_add", default: {}
    t.json "options_to_remove", default: {}
    t.boolean "combo"
    t.bigint "combo_item_id"
    t.integer "combo_quantity"
    t.boolean "out_of_stock", default: false
    t.string "combo_name"
    t.string "dish_type"
    t.integer "category_id"
    t.integer "sub_category_id"
    t.string "pet_pooja_taxes", default: [], array: true
    t.index ["combo_item_id"], name: "index_details_order_items_on_combo_item_id"
    t.index ["name"], name: "index_details_order_items_on_name"
    t.index ["order_id"], name: "index_details_order_items_on_order_id"
    t.index ["partner_item_id"], name: "index_details_order_items_on_partner_item_id"
    t.index ["quantity"], name: "index_details_order_items_on_quantity"
    t.index ["total_price_with_tax"], name: "index_details_order_items_on_total_price_with_tax"
    t.index ["unit_price"], name: "index_details_order_items_on_unit_price"
    t.index ["unit_weight"], name: "index_details_order_items_on_unit_weight"
    t.index ["zomato_item_addon_group_id"], name: "index_details_order_items_on_zomato_item_addon_group_id"
    t.index ["zomato_item_addon_id"], name: "index_details_order_items_on_zomato_item_addon_id"
    t.index ["zomato_item_group_choice_id"], name: "index_details_order_items_on_zomato_item_group_choice_id"
    t.index ["zomato_item_group_id"], name: "index_details_order_items_on_zomato_item_group_id"
    t.index ["zomato_item_id"], name: "index_details_order_items_on_zomato_item_id"
    t.index ["zomato_item_variant_id"], name: "index_details_order_items_on_zomato_item_variant_id"
  end

  create_table "devices", force: :cascade do |t|
    t.string "uuid"
    t.string "imei"
    t.string "platform"
    t.string "notification_id"
    t.string "model"
    t.string "os_version"
    t.integer "version"
    t.integer "status", default: 2
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "package_name", default: ""
    t.index ["notification_id"], name: "index_devices_on_notification_id"
    t.index ["package_name"], name: "index_devices_on_package_name"
    t.index ["platform"], name: "index_devices_on_platform"
    t.index ["user_id", "uuid", "package_name"], name: "index_devices_on_user_id_and_uuid_and_package_name"
    t.index ["user_id"], name: "index_devices_on_user_id"
    t.index ["uuid"], name: "index_devices_on_uuid"
    t.index ["version"], name: "index_devices_on_version"
  end

  create_table "email_subscriptions", force: :cascade do |t|
    t.string "email"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "enquiries", force: :cascade do |t|
    t.string "name"
    t.string "contact_number"
    t.string "message"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contact_number"], name: "index_enquiries_on_contact_number"
  end

  create_table "firebase_devices", force: :cascade do |t|
    t.string "device_id"
    t.string "fcm_token"
    t.string "firebase_user_id"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_firebase_devices_on_user_id"
  end

  create_table "flipper_features", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_flipper_features_on_key", unique: true
  end

  create_table "flipper_gates", force: :cascade do |t|
    t.string "feature_key", null: false
    t.string "key", null: false
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feature_key", "key", "value"], name: "index_flipper_gates_on_feature_key_and_key_and_value", unique: true
  end

  create_table "fssai_details", force: :cascade do |t|
    t.string "fssai_number"
    t.string "certificate"
    t.bigint "restaurant_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["restaurant_id"], name: "index_fssai_details_on_restaurant_id"
  end

  create_table "good_job_batches", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "description"
    t.jsonb "serialized_properties"
    t.text "on_finish"
    t.text "on_success"
    t.text "on_discard"
    t.text "callback_queue_name"
    t.integer "callback_priority"
    t.datetime "enqueued_at"
    t.datetime "discarded_at"
    t.datetime "finished_at"
  end

  create_table "good_job_executions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.uuid "active_job_id", null: false
    t.text "job_class"
    t.text "queue_name"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.text "error"
    t.integer "error_event", limit: 2
    t.text "error_backtrace", array: true
    t.uuid "process_id"
    t.interval "duration"
    t.index ["active_job_id", "created_at"], name: "index_good_job_executions_on_active_job_id_and_created_at"
    t.index ["process_id", "created_at"], name: "index_good_job_executions_on_process_id_and_created_at"
  end

  create_table "good_job_processes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.jsonb "state"
    t.integer "lock_type", limit: 2
  end

  create_table "good_job_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "key"
    t.jsonb "value"
    t.index ["key"], name: "index_good_job_settings_on_key", unique: true
  end

  create_table "good_jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "queue_name"
    t.integer "priority"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at"
    t.datetime "performed_at"
    t.datetime "finished_at"
    t.text "error"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.uuid "active_job_id"
    t.text "concurrency_key"
    t.text "cron_key"
    t.uuid "retried_good_job_id"
    t.datetime "cron_at"
    t.uuid "batch_id"
    t.uuid "batch_callback_id"
    t.boolean "is_discrete"
    t.integer "executions_count"
    t.text "job_class"
    t.integer "error_event", limit: 2
    t.text "labels", array: true
    t.uuid "locked_by_id"
    t.datetime "locked_at"
    t.index ["active_job_id", "created_at"], name: "index_good_jobs_on_active_job_id_and_created_at"
    t.index ["batch_callback_id"], name: "index_good_jobs_on_batch_callback_id", where: "(batch_callback_id IS NOT NULL)"
    t.index ["batch_id"], name: "index_good_jobs_on_batch_id", where: "(batch_id IS NOT NULL)"
    t.index ["concurrency_key"], name: "index_good_jobs_on_concurrency_key_when_unfinished", where: "(finished_at IS NULL)"
    t.index ["cron_key", "created_at"], name: "index_good_jobs_on_cron_key_and_created_at_cond", where: "(cron_key IS NOT NULL)"
    t.index ["cron_key", "cron_at"], name: "index_good_jobs_on_cron_key_and_cron_at_cond", unique: true, where: "(cron_key IS NOT NULL)"
    t.index ["finished_at"], name: "index_good_jobs_jobs_on_finished_at", where: "((retried_good_job_id IS NULL) AND (finished_at IS NOT NULL))"
    t.index ["labels"], name: "index_good_jobs_on_labels", where: "(labels IS NOT NULL)", using: :gin
    t.index ["locked_by_id"], name: "index_good_jobs_on_locked_by_id", where: "(locked_by_id IS NOT NULL)"
    t.index ["priority", "created_at"], name: "index_good_job_jobs_for_candidate_lookup", where: "(finished_at IS NULL)"
    t.index ["priority", "created_at"], name: "index_good_jobs_jobs_on_priority_created_at_when_unfinished", order: { priority: "DESC NULLS LAST" }, where: "(finished_at IS NULL)"
    t.index ["priority", "scheduled_at"], name: "index_good_jobs_on_priority_scheduled_at_unfinished_unlocked", where: "((finished_at IS NULL) AND (locked_by_id IS NULL))"
    t.index ["queue_name", "scheduled_at"], name: "index_good_jobs_on_queue_name_and_scheduled_at", where: "(finished_at IS NULL)"
    t.index ["scheduled_at"], name: "index_good_jobs_on_scheduled_at", where: "(finished_at IS NULL)"
  end

  create_table "gst_details", force: :cascade do |t|
    t.bigint "restaurant_id", null: false
    t.string "gst_number", null: false
    t.string "attachment"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "address_line1"
    t.text "address_line2"
    t.string "country"
    t.string "state"
    t.string "city"
    t.string "pincode"
    t.index ["restaurant_id"], name: "index_gst_details_on_restaurant_id"
  end

  create_table "invoice_generators", force: :cascade do |t|
    t.bigint "value"
    t.integer "start_at", default: 1
    t.boolean "reset", default: false
    t.string "prefix", default: ""
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "restaurant_id"
    t.integer "current_cycle", default: 1
    t.index ["restaurant_id"], name: "index_invoice_generators_on_restaurant_id"
    t.index ["start_at"], name: "index_invoice_generators_on_start_at"
  end

  create_table "item_prices", force: :cascade do |t|
    t.string "name"
    t.string "price_type"
    t.float "value", default: 0.0
    t.integer "status", default: 2
    t.integer "menu_item_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["price_type"], name: "index_item_prices_on_price_type"
    t.index ["status"], name: "index_item_prices_on_status"
  end

  create_table "languages", force: :cascade do |t|
    t.string "name", null: false
    t.string "code", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["code"], name: "index_languages_on_code", unique: true
  end

  create_table "languages_locations", id: false, force: :cascade do |t|
    t.bigint "language_id", null: false
    t.bigint "location_id", null: false
    t.index ["language_id", "location_id"], name: "index_languages_locations_on_language_and_location", unique: true
    t.index ["location_id"], name: "index_languages_locations_on_location_id"
  end

  create_table "linked_apps", force: :cascade do |t|
    t.integer "restaurant_id"
    t.integer "app_id"
    t.integer "status"
    t.string "source"
    t.json "settings"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "external_api_key"
    t.bigint "location_id"
    t.boolean "subscribed", default: true
    t.index ["location_id"], name: "index_linked_apps_on_location_id"
  end

  create_table "location_settings", force: :cascade do |t|
    t.bigint "location_id"
    t.boolean "use_recommended_menu_sorting", default: true
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["location_id"], name: "index_location_settings_on_location_id"
  end

  create_table "locations", force: :cascade do |t|
    t.string "name"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.integer "business_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "zip_code"
    t.string "time_zone"
    t.string "address"
    t.string "place"
    t.boolean "ready_for_subscription"
    t.string "menu_update_status"
    t.string "gst_number"
    t.string "country_code", default: "+91"
    t.jsonb "location_timing", default: []
    t.json "features", default: {}
    t.boolean "master_flush_required", default: false
    t.bigint "currency_id"
    t.index ["currency_id"], name: "index_locations_on_currency_id"
  end

  create_table "menu_assistance_requests", force: :cascade do |t|
    t.bigint "location_id"
    t.jsonb "menu_handover"
    t.jsonb "dish_photos"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["location_id"], name: "index_menu_assistance_requests_on_location_id"
  end

  create_table "menu_categories", force: :cascade do |t|
    t.string "name", default: "", null: false
    t.text "description", default: "", null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "restaurant_id"
    t.integer "priority", default: 0
    t.index ["created_at"], name: "index_menu_categories_on_created_at"
    t.index ["priority", "created_at"], name: "index_menu_categories_on_priority_and_created_at"
    t.index ["priority"], name: "index_menu_categories_on_priority"
    t.index ["restaurant_id"], name: "index_menu_categories_on_restaurant_id"
  end

  create_table "menu_item_images", force: :cascade do |t|
    t.string "image"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "menu_items", force: :cascade do |t|
    t.string "name", default: "", null: false
    t.text "description"
    t.float "price", default: 0.0, null: false
    t.integer "status", default: 0, null: false
    t.boolean "veg", default: false, null: false
    t.boolean "halal"
    t.boolean "alcohol"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "menu_category_id"
    t.boolean "today_special", default: false
    t.bigint "restaurant_id"
    t.string "shortcut"
    t.boolean "kot_disabled", default: false
    t.bigint "printer_id"
    t.string "price_unit", default: "numbers"
    t.index ["created_at"], name: "index_menu_items_on_created_at"
    t.index ["kot_disabled"], name: "index_menu_items_on_kot_disabled"
    t.index ["menu_category_id"], name: "index_menu_items_on_menu_category_id"
    t.index ["price_unit"], name: "index_menu_items_on_price_unit"
    t.index ["printer_id"], name: "index_menu_items_on_printer_id"
    t.index ["restaurant_id"], name: "index_menu_items_on_restaurant_id"
    t.index ["shortcut"], name: "index_menu_items_on_shortcut"
    t.index ["today_special"], name: "index_menu_items_on_today_special"
  end

  create_table "meta_app_tokens", force: :cascade do |t|
    t.bigint "location_id"
    t.string "config_id"
    t.string "app_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["location_id"], name: "index_meta_app_tokens_on_location_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.text "message"
    t.string "notification_type"
    t.string "event"
    t.string "cta_text"
    t.text "cta_hyperlink"
    t.datetime "expires_at"
    t.datetime "read_at"
    t.string "notifiable_type"
    t.bigint "notifiable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "notification_attributes", default: {}
    t.string "read_via"
    t.boolean "closable", default: false
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable_type_and_notifiable_id"
  end

  create_table "order_activities", force: :cascade do |t|
    t.string "event"
    t.string "name"
    t.text "remarks"
    t.integer "status", default: 0
    t.datetime "started_at"
    t.datetime "completed_at"
    t.text "items", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.bigint "order_id"
    t.json "data", default: {}
    t.index ["completed_at"], name: "index_order_activities_on_completed_at"
    t.index ["event"], name: "index_order_activities_on_event"
    t.index ["order_id"], name: "index_order_activities_on_order_id"
    t.index ["user_id"], name: "index_order_activities_on_user_id"
  end

  create_table "order_items", force: :cascade do |t|
    t.string "name"
    t.float "quantity"
    t.float "unit_price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "order_id"
    t.bigint "menu_item_id"
    t.integer "status", default: 0
    t.integer "kot_part", default: 1
    t.float "base_price", default: 0.0
    t.json "item_prices", default: []
    t.string "quantity_unit", default: "numbers"
    t.index ["base_price"], name: "index_order_items_on_base_price"
    t.index ["menu_item_id"], name: "index_order_items_on_menu_item_id"
    t.index ["name"], name: "index_order_items_on_name"
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["quantity_unit"], name: "index_order_items_on_quantity_unit"
    t.index ["status", "order_id"], name: "index_on_order_items_with_status_and_order_id"
  end

  create_table "order_payments", force: :cascade do |t|
    t.string "mode"
    t.float "amount"
    t.json "extra_data", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "order_id"
    t.integer "status", default: 0
    t.string "category"
    t.index ["amount"], name: "index_order_payments_on_amount"
    t.index ["category"], name: "index_order_payments_on_category"
    t.index ["mode"], name: "index_order_payments_on_mode"
    t.index ["order_id"], name: "index_order_payments_on_order_id"
  end

  create_table "orders", force: :cascade do |t|
    t.string "invoice_id"
    t.string "token_id"
    t.string "order_type"
    t.string "source", default: "default"
    t.string "table"
    t.integer "status", default: 0
    t.integer "guests_count"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.float "base_amount", default: 0.0
    t.float "payable_amount", default: 0.0
    t.float "balance_amount", default: 0.0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "restaurant_id"
    t.bigint "user_id"
    t.bigint "team_member_id"
    t.json "other_prices", default: {}
    t.string "table_reference", default: ""
    t.string "customer_mobile"
    t.text "delivery_address"
    t.integer "kot_print_status", default: 0
    t.integer "bill_print_status", default: 0
    t.float "bill_amount", default: 0.0
    t.float "round_off", default: 0.0
    t.integer "audit_status", default: 0
    t.bigint "day_audit_id"
    t.string "mode"
    t.string "source_id"
    t.datetime "invoice_time"
    t.integer "invoice_cycle", default: 1
    t.text "extra_note"
    t.string "partner"
    t.string "partner_order_id"
    t.string "customer_name"
    t.string "customer_email"
    t.string "instructions"
    t.float "item_level_total_charges"
    t.float "item_level_total_taxes"
    t.float "order_level_total_charges"
    t.float "order_level_total_taxes"
    t.bigint "biz_id"
    t.float "item_taxes"
    t.bigint "merchant_ref_id"
    t.float "total_charges"
    t.float "total_taxes"
    t.float "discount"
    t.string "accepted_by"
    t.string "bill_generated_by"
    t.string "picked_by"
    t.json "payment"
    t.string "delivery_type"
    t.float "merchant_receivable_amount"
    t.float "delivery_datetime"
    t.float "total_external_discount"
    t.bigint "rider_status_id"
    t.datetime "accepted_at"
    t.datetime "ready_at"
    t.datetime "dispatched_at"
    t.integer "order_preparation_time", default: 20
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.string "delivery_area"
    t.string "swiggy_customer_id"
    t.string "swiggy_barcode_id"
    t.string "customer_masked_number"
    t.string "customer_masked_number_pin"
    t.datetime "on_hold_at"
    t.datetime "cancel_at"
    t.bigint "whatsapp_customer_id"
    t.bigint "whatsapp_session_id"
    t.decimal "delivery_charge", precision: 8, scale: 2
    t.string "pickup_otp"
    t.string "drop_otp"
    t.string "return_otp"
    t.string "logistics_partner"
    t.string "logistics_partner_id"
    t.float "restaurant_delivery_charge", default: 0.0
    t.float "customer_delivery_charge", default: 0.0
    t.date "updated_date"
    t.index "date_trunc('day'::text, completed_at)", name: "index_orders_on_date_trunc_day_completed_at"
    t.index ["audit_status"], name: "index_orders_on_audit_status"
    t.index ["completed_at"], name: "index_orders_on_completed_at"
    t.index ["created_at"], name: "index_orders_on_created_at"
    t.index ["customer_mobile"], name: "index_orders_on_customer_mobile"
    t.index ["day_audit_id"], name: "index_orders_on_day_audit_id"
    t.index ["invoice_cycle"], name: "index_orders_on_invoice_cycle"
    t.index ["invoice_time"], name: "index_orders_on_invoice_time"
    t.index ["logistics_partner_id"], name: "index_orders_on_logistics_partner_id"
    t.index ["mode"], name: "index_orders_on_mode"
    t.index ["order_type"], name: "index_orders_on_order_type"
    t.index ["partner_order_id"], name: "index_orders_on_partner_order_id", unique: true
    t.index ["restaurant_id", "invoice_id", "invoice_cycle"], name: "index_orders_on_restaurant_id_and_invoice_id_and_invoice_cycle", unique: true
    t.index ["restaurant_id", "status"], name: "index_on_orders_with_restaurant_id_and_status"
    t.index ["restaurant_id"], name: "index_orders_on_restaurant_id"
    t.index ["source"], name: "index_orders_on_source"
    t.index ["source_id"], name: "index_orders_on_source_id"
    t.index ["started_at", "completed_at"], name: "index_orders_on_started_at_and_completed_at"
    t.index ["status"], name: "index_orders_on_status"
    t.index ["table", "table_reference"], name: "index_orders_on_table_and_table_reference"
    t.index ["table"], name: "index_orders_on_table"
    t.index ["table_reference"], name: "index_orders_on_table_reference"
    t.index ["team_member_id"], name: "index_orders_on_team_member_id"
    t.index ["updated_date"], name: "index_orders_on_updated_date"
    t.index ["user_id"], name: "index_orders_on_user_id"
    t.index ["whatsapp_customer_id"], name: "index_orders_on_whatsapp_customer_id"
    t.index ["whatsapp_session_id"], name: "index_orders_on_whatsapp_session_id"
  end

  create_table "payment_gateway_countries", force: :cascade do |t|
    t.string "country", null: false
    t.string "payment_gateway", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["country", "payment_gateway"], name: "index_payment_gateway_countries_on_country_and_gateway", unique: true
    t.index ["country"], name: "index_payment_gateway_countries_on_country"
  end

  create_table "pet_pooja_item_availabilities", force: :cascade do |t|
    t.jsonb "payload"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "pet_pooja_menu_updates", force: :cascade do |t|
    t.jsonb "payload"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "pet_pooja_order_updates", force: :cascade do |t|
    t.jsonb "payload"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "pet_pooja_store_updates", force: :cascade do |t|
    t.text "payload"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "pet_pooja_taxes", force: :cascade do |t|
    t.string "name"
    t.string "pet_pooja_ref_id"
    t.float "tax"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["pet_pooja_ref_id"], name: "index_pet_pooja_taxes_on_pet_pooja_ref_id"
  end

  create_table "platforms", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "point_of_contacts", force: :cascade do |t|
    t.bigint "restaurant_id"
    t.string "name"
    t.string "phone_number"
    t.string "updates_shared_via"
    t.string "updates_shared_to"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "country_code", default: "91"
    t.string "email"
    t.index ["restaurant_id"], name: "index_point_of_contacts_on_restaurant_id"
  end

  create_table "porter_logistics_logs", force: :cascade do |t|
    t.jsonb "webhook_response"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "price_infos", force: :cascade do |t|
    t.string "name"
    t.string "price_type"
    t.boolean "active", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "restaurant_id"
    t.float "value", default: 0.0
    t.integer "priority", default: 0
    t.index ["name", "price_type", "restaurant_id"], name: "index_price_infos_on_name_and_price_type_and_restaurant_id"
    t.index ["restaurant_id"], name: "index_price_infos_on_restaurant_id"
  end

  create_table "printers", force: :cascade do |t|
    t.string "name"
    t.string "nickname"
    t.string "tag"
    t.integer "status", default: 0
    t.bigint "restaurant_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_master_printer", default: false
    t.bigint "location_id"
    t.index ["location_id"], name: "index_printers_on_location_id"
    t.index ["name", "tag"], name: "index_printers_on_name_and_tag"
    t.index ["name"], name: "index_printers_on_name"
    t.index ["restaurant_id"], name: "index_printers_on_restaurant_id"
    t.index ["status"], name: "index_printers_on_status"
    t.index ["tag"], name: "index_printers_on_tag"
  end

  create_table "product_sales", force: :cascade do |t|
    t.string "order_type"
    t.date "orders_date"
    t.string "name"
    t.string "menu_category"
    t.integer "total_quantity", default: 0
    t.float "unit_price", default: 0.0
    t.float "total_amount", default: 0.0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "day_audit_id"
    t.string "quantity_unit", default: "numbers"
    t.index ["day_audit_id"], name: "index_product_sales_on_day_audit_id"
    t.index ["menu_category"], name: "index_product_sales_on_menu_category"
    t.index ["name", "unit_price"], name: "index_product_sales_on_name_and_unit_price"
    t.index ["name"], name: "index_product_sales_on_name"
    t.index ["order_type"], name: "index_product_sales_on_order_type"
    t.index ["orders_date"], name: "index_product_sales_on_orders_date"
    t.index ["quantity_unit"], name: "index_product_sales_on_quantity_unit"
  end

  create_table "qwqer_webhook_logs", force: :cascade do |t|
    t.jsonb "webhook_response", default: {}, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "razorpay_events", force: :cascade do |t|
    t.json "payload"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "x_razorpay_event_id"
    t.boolean "processed"
    t.index ["x_razorpay_event_id"], name: "index_razorpay_events_on_x_razorpay_event_id"
  end

  create_table "recommended_items", force: :cascade do |t|
    t.string "name"
    t.string "image"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "restaurant_availability_events", force: :cascade do |t|
    t.bigint "restaurant_id"
    t.integer "event_name"
    t.integer "channel"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "event_at"
    t.string "platform"
    t.index ["restaurant_id"], name: "index_restaurant_availability_events_on_restaurant_id"
  end

  create_table "restaurant_feedbacks", force: :cascade do |t|
    t.text "content"
    t.bigint "user_id"
    t.bigint "restaurant_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 2
    t.text "topic"
    t.text "feature_reference"
    t.index ["restaurant_id"], name: "index_restaurant_feedbacks_on_restaurant_id"
    t.index ["user_id"], name: "index_restaurant_feedbacks_on_user_id"
  end

  create_table "restaurant_platforms", force: :cascade do |t|
    t.string "login_id"
    t.string "partner_url"
    t.bigint "restaurant_id"
    t.bigint "platform_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "state"
    t.string "disintegration_reason"
    t.string "meta_business_manager_id"
    t.string "restaurant_logo"
    t.string "display_name"
    t.string "whatsapp_business_number"
    t.string "website"
    t.string "email"
    t.text "business_description"
    t.text "address"
    t.float "delivery_charge", default: 0.0, null: false
    t.float "delivery_charge_from", default: 0.0, null: false
    t.float "free_delivery_order_value", default: 0.0, null: false
    t.float "flat_delivery_charge", default: 0.0, null: false
    t.json "meta_data", default: {}, null: false
    t.string "payment_mode", default: [], array: true
    t.index ["platform_id"], name: "index_restaurant_platforms_on_platform_id"
    t.index ["restaurant_id"], name: "index_restaurant_platforms_on_restaurant_id"
  end

  create_table "restaurant_settlements", force: :cascade do |t|
    t.string "restaurant_name"
    t.float "previous_dues", default: 0.0
    t.float "settlement_amount", default: 0.0
    t.datetime "settled_on"
    t.string "settlement_status"
    t.string "razorpay_status"
    t.bigint "restaurant_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["restaurant_id"], name: "index_restaurant_settlements_on_restaurant_id"
  end

  create_table "restaurants", force: :cascade do |t|
    t.string "name", default: "", null: false
    t.string "phone_number"
    t.string "email"
    t.text "address", default: "", null: false
    t.text "short_note", default: "", null: false
    t.string "place"
    t.string "tagline"
    t.string "cuisines", default: [], array: true
    t.boolean "veg", default: false, null: false
    t.string "website"
    t.string "facebook"
    t.string "twitter"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.string "logo"
    t.integer "status", default: 2
    t.integer "payment_status", default: 0
    t.string "country_code", default: "IN"
    t.string "country_number", default: "91"
    t.string "gst_number"
    t.json "printer_settings", default: {"kot_print"=>1, "customer_copy"=>1, "restaurant_copy"=>1, "dispatch_copy"=>1, "take_away_slip"=>1}
    t.boolean "auto_accept", default: false
    t.boolean "sms_enabled", default: false
    t.json "features", default: {"dine_in"=>false}
    t.boolean "ac_menu_enabled", default: false
    t.string "socket_uuid"
    t.string "kot_controller"
    t.string "outlet_id"
    t.string "time_zone"
    t.text "update_data_status"
    t.json "zip_codes"
    t.datetime "subscribe_time"
    t.integer "urban_piper_store_id"
    t.json "delivery_charge"
    t.string "update_availability_status"
    t.boolean "biller_enable", default: true
    t.text "country"
    t.boolean "hygiene_check", default: false
    t.integer "allowed_no_of_cancellations", default: 0
    t.integer "order_acceptance_time", default: 0
    t.string "restaurant_type", default: "outlet"
    t.boolean "cloud_kitchen_enabled", default: false
    t.jsonb "channel_settings", default: []
    t.jsonb "restaurant_timing", default: []
    t.datetime "trial_start_date"
    t.boolean "ready_for_subscription", default: false
    t.datetime "subscription_due_date"
    t.integer "location_id"
    t.boolean "urban_piper_published", default: false
    t.string "whatsapp_business_number"
    t.string "airtel_iq_api_key"
    t.string "integration_status"
    t.integer "whatsapp_delivery_radius"
    t.decimal "whatsapp_delivery_charge", precision: 8, scale: 2
    t.string "whatsapp_otp"
    t.integer "pipefy_card_id"
    t.integer "pipefy_phase_id"
    t.integer "whatsapp_discount_percentage", default: 0
    t.string "airtel_api_username"
    t.string "airtel_api_password"
    t.string "custom_offline_message"
    t.string "razorpay_account_id"
    t.string "pet_pooja_ref_id"
    t.datetime "tos_agreed_at"
    t.string "whatsapp_display_name"
    t.string "vat_number"
    t.index "ll_to_earth((latitude)::double precision, (longitude)::double precision)", name: "index_restaurants_location_gist", using: :gist
    t.index ["ac_menu_enabled"], name: "index_restaurants_on_ac_menu_enabled"
    t.index ["country_code", "country_number"], name: "index_restaurants_on_country_code_and_country_number"
    t.index ["email"], name: "index_restaurants_on_email"
    t.index ["latitude"], name: "index_restaurants_on_latitude"
    t.index ["longitude"], name: "index_restaurants_on_longitude"
    t.index ["outlet_id"], name: "index_restaurants_on_outlet_id", unique: true
    t.index ["payment_status"], name: "index_restaurants_on_payment_status"
    t.index ["pet_pooja_ref_id"], name: "index_restaurants_on_pet_pooja_ref_id"
    t.index ["place"], name: "index_restaurants_on_place"
    t.index ["socket_uuid"], name: "index_restaurants_on_socket_uuid", unique: true
    t.index ["status"], name: "index_restaurants_on_status"
  end

  create_table "reviews", force: :cascade do |t|
    t.string "reviewable_type", null: false
    t.bigint "reviewable_id", null: false
    t.string "reviewer_type", null: false
    t.bigint "reviewer_id", null: false
    t.float "rating", null: false
    t.text "comment"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["reviewable_type", "reviewable_id"], name: "index_reviews_on_reviewable_type_and_reviewable_id"
    t.index ["reviewer_type", "reviewer_id"], name: "index_reviews_on_reviewer_type_and_reviewer_id"
  end

  create_table "rider_statuses", force: :cascade do |t|
    t.string "channel_name"
    t.bigint "channel_order_id"
    t.string "current_state"
    t.bigint "delivery_person_alt_phone"
    t.bigint "delivery_person_phone"
    t.string "delivery_person_name"
    t.bigint "channel_user_id"
    t.bigint "order_id"
    t.string "mode"
    t.json "status_updates"
    t.integer "restaurant_id"
    t.bigint "channel_store_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "order_return_otp"
    t.string "driver_id"
    t.string "status"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name"
    t.string "resource_type"
    t.bigint "resource_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id"
    t.index ["name"], name: "index_roles_on_name"
    t.index ["resource_type", "resource_id"], name: "index_roles_on_resource_type_and_resource_id"
  end

  create_table "sales_summaries", force: :cascade do |t|
    t.string "order_type"
    t.date "orders_date"
    t.integer "bill_count", default: 0
    t.float "bill_amount", default: 0.0
    t.float "cash", default: 0.0
    t.float "card", default: 0.0
    t.float "voucher", default: 0.0
    t.float "mobile", default: 0.0
    t.float "discount", default: 0.0
    t.float "balance", default: 0.0
    t.float "round_off", default: 0.0
    t.float "sgst", default: 0.0
    t.float "cgst", default: 0.0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "day_audit_id"
    t.float "round_up", default: 0.0
    t.float "round_down", default: 0.0
    t.index ["bill_amount"], name: "index_sales_summaries_on_bill_amount"
    t.index ["bill_count"], name: "index_sales_summaries_on_bill_count"
    t.index ["day_audit_id"], name: "index_sales_summaries_on_day_audit_id"
    t.index ["order_type"], name: "index_sales_summaries_on_order_type"
    t.index ["orders_date"], name: "index_sales_summaries_on_orders_date"
  end

  create_table "service_credentials", force: :cascade do |t|
    t.string "name"
    t.string "access_token"
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_service_credentials_on_name", unique: true
  end

  create_table "settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "app"
    t.integer "health_metrics_order_acceptance_time"
    t.integer "health_metrics_preparation_time"
    t.integer "health_metrics_pickup_time"
    t.integer "health_metrics_delivery_time"
    t.integer "health_metrics_cancellations_per_day"
    t.integer "health_metrics_business_hours"
    t.boolean "enable_auto_accept"
    t.boolean "enable_auto_store_availability"
    t.boolean "enable_order_confirmation_popup"
    t.boolean "enable_hygiene_check"
    t.boolean "enable_print_bill"
    t.boolean "enable_consolidated_kot_printer"
    t.bigint "restaurant_id"
    t.boolean "use_recommended_menu_sorting"
    t.index ["restaurant_id"], name: "index_settings_on_restaurant_id"
  end

  create_table "settlements", force: :cascade do |t|
    t.string "restaurant_name"
    t.string "whatsapp_order_id"
    t.float "bill_amount"
    t.float "discount"
    t.float "payable_amount"
    t.float "customer_delivery_charge"
    t.float "restaurant_delivery_charge"
    t.float "payment_handling_charge"
    t.float "foaps_commission"
    t.float "restaurant_recievable_amount"
    t.string "kot_order_id"
    t.string "order_type"
    t.string "order_status"
    t.string "order_id"
    t.bigint "restaurant_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "restaurant_settlement_id", null: false
    t.boolean "transfer_status", default: false
    t.float "delivery_charge"
    t.string "partner_order_id"
    t.string "settlement_status"
    t.string "payment_id"
    t.string "utr_number"
    t.datetime "settled_time"
    t.datetime "completed_at"
    t.datetime "order_date"
    t.index ["order_id"], name: "index_settlements_on_order_id", unique: true
    t.index ["restaurant_id"], name: "index_settlements_on_restaurant_id"
    t.index ["restaurant_settlement_id"], name: "index_settlements_on_restaurant_settlement_id"
  end

  create_table "shortcut_sequences", force: :cascade do |t|
    t.bigint "value"
    t.integer "start_at", default: 1
    t.boolean "reset", default: false
    t.string "prefix", default: ""
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "restaurant_id"
    t.index ["restaurant_id"], name: "index_shortcut_sequences_on_restaurant_id"
    t.index ["start_at"], name: "index_shortcut_sequences_on_start_at"
  end

  create_table "store_carts", force: :cascade do |t|
    t.integer "customer_id"
    t.string "customer_type"
    t.string "state"
    t.integer "restaurant_id"
    t.jsonb "items"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "whatsapp_address_id"
    t.string "customer_notes"
    t.float "total_amount"
    t.float "cgst"
    t.float "sgst"
    t.float "packaging_charges"
    t.float "delivery_charges", default: 0.0
    t.float "discounts"
    t.float "total_amount_to_pay"
    t.string "order_type"
    t.bigint "whatsapp_order_id"
    t.string "source"
    t.string "payment_mode"
    t.float "vat"
    t.index ["whatsapp_address_id"], name: "index_store_carts_on_whatsapp_address_id"
    t.index ["whatsapp_order_id"], name: "index_store_carts_on_whatsapp_order_id"
  end

  create_table "store_login_tokens", force: :cascade do |t|
    t.string "token"
    t.bigint "whatsapp_customer_id"
    t.bigint "restaurant_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "business_number"
    t.string "order_type"
    t.string "source"
    t.index ["restaurant_id"], name: "index_store_login_tokens_on_restaurant_id"
    t.index ["whatsapp_customer_id"], name: "index_store_login_tokens_on_whatsapp_customer_id"
  end

  create_table "surveys", force: :cascade do |t|
    t.bigint "location_id"
    t.string "name"
    t.string "submitted_by"
    t.string "status"
    t.datetime "submitted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["location_id"], name: "index_surveys_on_location_id"
  end

  create_table "suspicious_actions", force: :cascade do |t|
    t.string "action"
    t.date "completed_date"
    t.float "amount_before", default: 0.0
    t.float "amount_after", default: 0.0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.bigint "restaurant_id"
    t.bigint "order_id"
    t.bigint "action_activity_id"
    t.bigint "order_create_activity_id"
    t.index ["action"], name: "index_suspicious_actions_on_action"
    t.index ["action_activity_id"], name: "index_suspicious_actions_on_action_activity_id"
    t.index ["completed_date"], name: "index_suspicious_actions_on_completed_date"
    t.index ["order_create_activity_id"], name: "index_suspicious_actions_on_order_create_activity_id"
    t.index ["order_id"], name: "index_suspicious_actions_on_order_id"
    t.index ["restaurant_id"], name: "index_suspicious_actions_on_restaurant_id"
    t.index ["user_id"], name: "index_suspicious_actions_on_user_id"
  end

  create_table "team_members", force: :cascade do |t|
    t.string "mobile_number"
    t.string "initial_roles", default: [], array: true
    t.integer "status", default: 0
    t.datetime "invite_sent_at"
    t.datetime "invite_accepted_at"
    t.bigint "user_id"
    t.bigint "restaurant_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "invite_token"
    t.json "data", default: {}
    t.bigint "location_id"
    t.string "email"
    t.index ["invite_token"], name: "index_team_members_on_invite_token"
    t.index ["location_id"], name: "index_team_members_on_location_id"
    t.index ["mobile_number", "restaurant_id"], name: "index_team_members_on_mobile_number_and_restaurant_id"
    t.index ["mobile_number"], name: "index_team_members_on_mobile_number"
    t.index ["restaurant_id"], name: "index_team_members_on_restaurant_id"
    t.index ["user_id"], name: "index_team_members_on_user_id"
  end

  create_table "token_generators", force: :cascade do |t|
    t.bigint "value"
    t.integer "start_at", default: 1
    t.boolean "reset", default: false
    t.string "prefix", default: ""
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "restaurant_id"
    t.bigint "location_id"
    t.index ["location_id"], name: "index_token_generators_on_location_id"
    t.index ["restaurant_id"], name: "index_token_generators_on_restaurant_id"
    t.index ["start_at"], name: "index_token_generators_on_start_at"
  end

  create_table "trashes", force: :cascade do |t|
    t.integer "record_type", default: 0, null: false
    t.integer "status", default: 2
    t.json "data", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "restaurant_id"
    t.index ["record_type"], name: "index_trashes_on_record_type"
    t.index ["restaurant_id"], name: "index_trashes_on_restaurant_id"
    t.index ["status"], name: "index_trashes_on_status"
  end

  create_table "urban_piper_api_logs", force: :cascade do |t|
    t.string "foaps_request_id"
    t.text "request_path"
    t.text "request_method"
    t.text "request_body"
    t.text "response_body"
    t.text "response_code"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_roles", force: :cascade do |t|
    t.integer "status", default: 2
    t.bigint "user_id"
    t.bigint "role_id"
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["status"], name: "index_user_roles_on_status"
    t.index ["user_id", "role_id"], name: "index_user_roles_on_user_id_and_role_id"
    t.index ["user_id"], name: "index_user_roles_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "provider", default: "email", null: false
    t.string "uid", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.string "name"
    t.string "nickname"
    t.string "image"
    t.string "email"
    t.json "tokens"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "mobile_number"
    t.string "otp_secret"
    t.integer "otp_count"
    t.integer "otp_status", default: 0
    t.json "register_info", default: {}
    t.string "gender"
    t.date "dob"
    t.boolean "vegetarian", default: false
    t.string "referral_code"
    t.string "avatar"
    t.boolean "registered", default: false
    t.datetime "otp_created_at"
    t.datetime "mobile_confirmed_at"
    t.string "country_code", default: "IN"
    t.string "country_number", default: "91"
    t.boolean "allow_password_change", default: false, null: false
    t.string "item_image"
    t.boolean "beta_user", default: false
    t.string "email_otp_secret"
    t.datetime "email_otp_generated_at"
    t.datetime "email_otp_verified_at"
    t.boolean "email_registered"
    t.string "source"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["country_code", "country_number"], name: "index_users_on_country_code_and_country_number"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["mobile_number"], name: "index_users_on_mobile_number", unique: true
    t.index ["referral_code"], name: "index_users_on_referral_code"
    t.index ["registered"], name: "index_users_on_registered"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true
    t.index ["uid"], name: "index_users_on_uid", unique: true
  end

  create_table "whatsapp_addresses", force: :cascade do |t|
    t.bigint "whatsapp_customer_id"
    t.text "address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.string "house_number"
    t.string "landmark"
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_whatsapp_addresses_on_deleted_at"
    t.index ["whatsapp_customer_id"], name: "index_whatsapp_addresses_on_whatsapp_customer_id"
  end

  create_table "whatsapp_custom_buttons", force: :cascade do |t|
    t.string "whatsapp_business_number"
    t.string "custom_button_name"
    t.text "button_content"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "functionality"
  end

  create_table "whatsapp_customers", force: :cascade do |t|
    t.string "phone_number"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "current_address"
    t.string "order_type", default: "home_delivery"
    t.string "preferred_language"
  end

  create_table "whatsapp_fb_commerce_manager_catalogs", force: :cascade do |t|
    t.string "fb_business_id"
    t.string "fb_catalog_id"
    t.integer "owner_id"
    t.string "owner_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "access_token"
    t.string "fb_data_feed_id"
  end

  create_table "whatsapp_message_templates", force: :cascade do |t|
    t.string "key", null: false
    t.string "locale", default: "en", null: false
    t.text "body", null: false
    t.string "description"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["key", "locale"], name: "index_whatsapp_message_templates_on_key_and_locale", unique: true
  end

  create_table "whatsapp_messages", force: :cascade do |t|
    t.text "payload"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "whatsapp_session_id"
    t.string "hashed_payload"
    t.index ["whatsapp_session_id"], name: "index_whatsapp_messages_on_whatsapp_session_id"
  end

  create_table "whatsapp_orders", force: :cascade do |t|
    t.jsonb "order_params"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "whatsapp_customer_id"
    t.string "status"
    t.jsonb "items_in_cart", default: []
    t.bigint "restaurant_id"
    t.string "order_type"
    t.string "payment_link_id"
    t.boolean "payment_link_cancelled"
    t.string "tracking_url"
    t.string "order_id"
    t.integer "porter_retry_count", default: 0
    t.string "driver_status"
    t.string "cancellation_reason", default: [], array: true
    t.string "captured_order_id"
    t.index ["restaurant_id"], name: "index_whatsapp_orders_on_restaurant_id"
    t.index ["whatsapp_customer_id"], name: "index_whatsapp_orders_on_whatsapp_customer_id"
  end

  create_table "whatsapp_payment_provider_orders", force: :cascade do |t|
    t.bigint "whatsapp_order_id", null: false
    t.string "payment_provider"
    t.string "payment_provider_reference_id"
    t.string "payment_status"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "amount"
    t.index ["whatsapp_order_id"], name: "index_whatsapp_payment_provider_orders_on_whatsapp_order_id"
  end

  create_table "whatsapp_sessions", force: :cascade do |t|
    t.text "session_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "current_address_id"
    t.bigint "whatsapp_customer_id"
    t.bigint "restaurant_id"
    t.string "order_type"
    t.index ["restaurant_id"], name: "index_whatsapp_sessions_on_restaurant_id"
    t.index ["whatsapp_customer_id"], name: "index_whatsapp_sessions_on_whatsapp_customer_id"
  end

  create_table "working_days", force: :cascade do |t|
    t.string "day"
    t.integer "priority"
    t.boolean "active", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "restaurant_id"
    t.jsonb "events", default: "{}", null: false
    t.index ["day", "restaurant_id"], name: "index_working_days_on_day_and_restaurant_id"
    t.index ["restaurant_id"], name: "index_working_days_on_restaurant_id"
  end

  create_table "zomato_addon_groups", force: :cascade do |t|
    t.integer "zomato_item_id"
    t.string "name"
    t.text "desc"
    t.integer "max_selection"
    t.integer "min_selection"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "pet_pooja_ref_id"
    t.index ["pet_pooja_ref_id"], name: "index_zomato_addon_groups_on_pet_pooja_ref_id"
  end

  create_table "zomato_categories", force: :cascade do |t|
    t.string "category_name"
    t.string "category_description"
    t.string "category_image_url"
    t.string "category_tags", default: [], array: true
    t.integer "category_is_active", default: 1
    t.integer "has_subcategory", default: 0
    t.integer "category_order"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "restaurant_id"
    t.integer "status", default: 0
    t.string "week_days", default: [], array: true
    t.jsonb "time_slots"
    t.datetime "endDate"
    t.datetime "startDate"
    t.datetime "deleted_at"
    t.bigint "location_id"
    t.integer "restaurant_ids", default: [], array: true
    t.boolean "whatsapp_enabled", default: false
    t.string "pet_pooja_ref_id"
    t.index ["category_is_active"], name: "index_zomato_categories_on_category_is_active"
    t.index ["category_name"], name: "index_zomato_categories_on_category_name"
    t.index ["category_order"], name: "index_zomato_categories_on_category_order"
    t.index ["deleted_at"], name: "index_zomato_categories_on_deleted_at"
    t.index ["has_subcategory"], name: "index_zomato_categories_on_has_subcategory"
    t.index ["location_id"], name: "index_zomato_categories_on_location_id"
    t.index ["pet_pooja_ref_id"], name: "index_zomato_categories_on_pet_pooja_ref_id"
    t.index ["restaurant_id"], name: "index_zomato_categories_on_restaurant_id"
  end

  create_table "zomato_category_schedules", force: :cascade do |t|
    t.string "schedule_name"
    t.integer "schedule_day"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "zomato_category_id"
    t.index ["schedule_day"], name: "index_zomato_category_schedules_on_schedule_day"
    t.index ["zomato_category_id"], name: "index_zomato_category_schedules_on_zomato_category_id"
  end

  create_table "zomato_charge_taxes", force: :cascade do |t|
    t.string "order_type"
    t.string "taxes", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "zomato_charge_id"
    t.integer "status", default: 0
    t.index ["order_type"], name: "index_zomato_charge_taxes_on_order_type"
    t.index ["zomato_charge_id"], name: "index_zomato_charge_taxes_on_zomato_charge_id"
  end

  create_table "zomato_charges", force: :cascade do |t|
    t.string "charge_name"
    t.string "charge_type"
    t.float "charge_value", default: 0.0
    t.float "charge_amount", default: 0.0
    t.string "applicable_on"
    t.integer "charge_is_active", default: 1
    t.integer "charge_always_applicable", default: 1
    t.float "charge_applicable_below_order_amount", default: 0.0
    t.integer "has_tier_wise_values", default: 0
    t.float "charge_taxes_total", default: 0.0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "restaurant_id"
    t.integer "status", default: 0
    t.index ["restaurant_id"], name: "index_zomato_charges_on_restaurant_id"
  end

  create_table "zomato_group_items", force: :cascade do |t|
    t.bigint "zomato_group_id"
    t.bigint "zomato_item_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["zomato_group_id"], name: "index_zomato_group_items_on_zomato_group_id"
    t.index ["zomato_item_id"], name: "index_zomato_group_items_on_zomato_item_id"
  end

  create_table "zomato_groups", force: :cascade do |t|
    t.string "group_id"
    t.string "group_name"
    t.string "group_description"
    t.integer "group_minimum"
    t.integer "group_maximum"
    t.integer "group_is_active", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "restaurant_id"
    t.integer "status", default: 0
    t.integer "group_type", default: 0
    t.index ["group_name"], name: "index_zomato_groups_on_group_name"
    t.index ["restaurant_id"], name: "index_zomato_groups_on_restaurant_id"
  end

  create_table "zomato_item_addons", force: :cascade do |t|
    t.integer "zomato_item_id"
    t.integer "zomato_addon_id"
    t.string "apply_group"
    t.integer "apply_group_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "zomato_addon_group_id"
    t.string "apply_groups", array: true
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_zomato_item_addons_on_deleted_at"
  end

  create_table "zomato_item_charges", force: :cascade do |t|
    t.string "order_type"
    t.string "charges", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "zomato_item_id"
    t.index ["order_type"], name: "index_zomato_item_charges_on_order_type"
    t.index ["zomato_item_id"], name: "index_zomato_item_charges_on_zomato_item_id"
  end

  create_table "zomato_item_group_choice_variants", force: :cascade do |t|
    t.integer "zomato_item_choice_id"
    t.integer "zomato_item_group_choices_id"
    t.integer "price"
    t.integer "extra_price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "zomato_item_group_choices", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.integer "zomato_item_group_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "price"
    t.string "pricing_mode"
  end

  create_table "zomato_item_groups", force: :cascade do |t|
    t.bigint "zomato_item_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.integer "max_selection"
    t.integer "min_selection"
    t.string "group_types"
    t.index ["zomato_item_id"], name: "index_zomato_item_groups_on_zomato_item_id"
  end

  create_table "zomato_item_taxes", force: :cascade do |t|
    t.string "order_type"
    t.string "taxes", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "zomato_item_id"
    t.index ["order_type"], name: "index_zomato_item_taxes_on_order_type"
    t.index ["zomato_item_id"], name: "index_zomato_item_taxes_on_zomato_item_id"
  end

  create_table "zomato_item_variants", force: :cascade do |t|
    t.integer "zomato_item_id"
    t.string "name"
    t.string "description"
    t.integer "unit_price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_active", default: true
    t.datetime "deleted_at"
    t.boolean "pending_catalogue_sync", default: false
    t.boolean "pending_availability_sync", default: false
    t.string "pet_pooja_ref_id"
    t.string "pet_pooja_variant_ref_id"
    t.index ["deleted_at"], name: "index_zomato_item_variants_on_deleted_at"
    t.index ["pet_pooja_ref_id"], name: "index_zomato_item_variants_on_pet_pooja_ref_id"
  end

  
  create_table "zomato_items", force: :cascade do |t|
    t.string "item_name"
    t.string "item_short_description"
    t.string "item_long_description"
    t.string "item_image_url"
    t.string "item_tags", default: [], array: true
    t.float "item_unit_price", default: 0.0
    t.float "item_final_price", default: 0.0
    t.float "combo_reduced_price"
    t.integer "item_is_active", default: 1
    t.integer "item_in_stock", default: 1
    t.integer "item_order"
    t.integer "item_is_recommended", default: 0
    t.integer "item_is_default", default: 0
    t.integer "item_is_treats_active", default: 0
    t.integer "item_is_bogo_active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "zomato_category_id"
    t.bigint "zomato_subcategory_id"
    t.bigint "restaurant_id"
    t.integer "status", default: 0
    t.boolean "kot_disabled", default: false
    t.bigint "printer_id"
    t.integer "addon", default: 0
    t.integer "zomato_tax_id", default: [], array: true
    t.string "pricing_type", default: "advanced"
    t.string "variants_name"
    t.string "variants_description"
    t.string "addons_name"
    t.string "addons_description"
    t.boolean "special_item", default: false
    t.string "item_groups_name"
    t.string "item_groups_description"
    t.boolean "todays_special", default: false
    t.json "channels"
    t.string "price_unit"
    t.integer "zomato_master_item_id"
    t.json "dish_type"
    t.string "image"
    t.datetime "deleted_at"
    t.string "category_timing", default: [], array: true
    t.boolean "pending_catalogue_sync", default: false
    t.boolean "pending_availability_sync", default: false
    t.bigint "location_id"
    t.integer "restaurant_ids", default: [], array: true
    t.integer "sort_order"
    t.boolean "tax_exempted"
    t.string "tax_not_required_reason"
    t.string "pet_pooja_ref_id"
    t.string "pet_pooja_taxes", default: [], array: true
    t.index ["deleted_at"], name: "index_zomato_items_on_deleted_at"
    t.index ["item_final_price"], name: "index_zomato_items_on_item_final_price"
    t.index ["item_in_stock"], name: "index_zomato_items_on_item_in_stock"
    t.index ["item_is_bogo_active"], name: "index_zomato_items_on_item_is_bogo_active"
    t.index ["item_is_recommended"], name: "index_zomato_items_on_item_is_recommended"
    t.index ["item_name"], name: "index_zomato_items_on_item_name"
    t.index ["item_order"], name: "index_zomato_items_on_item_order"
    t.index ["item_unit_price"], name: "index_zomato_items_on_item_unit_price"
    t.index ["location_id"], name: "index_zomato_items_on_location_id"
    t.index ["pet_pooja_ref_id"], name: "index_zomato_items_on_pet_pooja_ref_id"
    t.index ["printer_id"], name: "index_zomato_items_on_printer_id"
    t.index ["restaurant_id"], name: "index_zomato_items_on_restaurant_id"
    t.index ["sort_order"], name: "index_zomato_items_on_sort_order"
    t.index ["zomato_category_id"], name: "index_zomato_items_on_zomato_category_id"
    t.index ["zomato_subcategory_id"], name: "index_zomato_items_on_zomato_subcategory_id"
  end

  create_table "zomato_logistics_logs", force: :cascade do |t|
    t.jsonb "webhook_response"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "zomato_master_items", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_zomato_master_items_on_name"
  end

  create_table "zomato_order_additional_charges", force: :cascade do |t|
    t.string "order_type"
    t.string "charges", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_type"], name: "index_zomato_order_additional_charges_on_order_type"
  end

  create_table "zomato_restaurant_offers", force: :cascade do |t|
    t.string "offer_id"
    t.string "offer_type"
    t.string "start_date"
    t.string "end_date"
    t.string "discount_type"
    t.float "discount_value", default: 0.0
    t.float "min_order_amount", default: 0.0
    t.integer "first_order_only", default: 0
    t.integer "is_active", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discount_type"], name: "index_zomato_restaurant_offers_on_discount_type"
    t.index ["discount_value"], name: "index_zomato_restaurant_offers_on_discount_value"
    t.index ["end_date"], name: "index_zomato_restaurant_offers_on_end_date"
    t.index ["offer_type"], name: "index_zomato_restaurant_offers_on_offer_type"
    t.index ["start_date"], name: "index_zomato_restaurant_offers_on_start_date"
  end

  create_table "zomato_schedule_time_slots", force: :cascade do |t|
    t.string "start_time"
    t.string "end_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "zomato_category_schedules_id"
    t.index ["end_time"], name: "index_zomato_schedule_time_slots_on_end_time"
    t.index ["start_time"], name: "index_zomato_schedule_time_slots_on_start_time"
    t.index ["zomato_category_schedules_id"], name: "zomato_schedule_time_slots_category_schedule_id"
  end

  create_table "zomato_subcategories", force: :cascade do |t|
    t.string "subcategory_name"
    t.string "subcategory_description"
    t.string "subcategory_image_url"
    t.string "subcategory_tags", default: [], array: true
    t.integer "subcategory_is_active", default: 1
    t.integer "subcategory_order"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "zomato_category_id"
    t.integer "status", default: 0
    t.datetime "deleted_at"
    t.string "pet_pooja_ref_id"
    t.index ["deleted_at"], name: "index_zomato_subcategories_on_deleted_at"
    t.index ["pet_pooja_ref_id"], name: "index_zomato_subcategories_on_pet_pooja_ref_id"
    t.index ["subcategory_is_active"], name: "index_zomato_subcategories_on_subcategory_is_active"
    t.index ["subcategory_name"], name: "index_zomato_subcategories_on_subcategory_name"
    t.index ["subcategory_order"], name: "index_zomato_subcategories_on_subcategory_order"
    t.index ["zomato_category_id"], name: "index_zomato_subcategories_on_zomato_category_id"
  end

  create_table "zomato_tags", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "veg", default: false
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "zomato_taxes", force: :cascade do |t|
    t.string "tax_name"
    t.string "tax_type"
    t.integer "tax_is_active", default: 1
    t.float "tax_value", default: 0.0
    t.float "tax_amount", default: 0.0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "restaurant_id"
    t.integer "status", default: 0
    t.string "identifier"
    t.string "service_type"
    t.string "country_code"
    t.string "global_identifier", default: ""
    t.index ["restaurant_id"], name: "index_zomato_taxes_on_restaurant_id"
    t.index ["tax_name"], name: "index_zomato_taxes_on_tax_name"
    t.index ["tax_type"], name: "index_zomato_taxes_on_tax_type"
    t.index ["tax_value"], name: "index_zomato_taxes_on_tax_value"
  end

  create_table "zomato_tier_wise_values", force: :cascade do |t|
    t.integer "tier_id"
    t.integer "charge_always_applicable"
    t.float "charge_value"
    t.float "charge_applicable_below_order_amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "zomato_charge_id"
    t.integer "status", default: 0
    t.index ["tier_id"], name: "index_zomato_tier_wise_values_on_tier_id"
    t.index ["zomato_charge_id"], name: "index_zomato_tier_wise_values_on_zomato_charge_id"
  end

  create_table "zomato_timings", force: :cascade do |t|
    t.string "start_time"
    t.string "end_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "zomato_restaurant_offer_id"
    t.index ["end_time"], name: "index_zomato_timings_on_end_time"
    t.index ["start_time"], name: "index_zomato_timings_on_start_time"
    t.index ["zomato_restaurant_offer_id"], name: "index_zomato_timings_on_zomato_restaurant_offer_id"
  end

  create_table "zomato_urban_call_statuses", force: :cascade do |t|
    t.integer "restaurant_id"
    t.string "urban_call_status"
    t.string "message"
    t.string "reference"
    t.string "request_for"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "variants"
    t.string "action"
    t.boolean "zomato_active"
    t.boolean "swiggy_active"
    t.boolean "dunzo_active"
    t.text "job_status"
    t.index ["reference"], name: "index_zomato_urban_call_statuses_on_reference"
  end

  add_foreign_key "app_subscriptions_invoice_items", "app_subscriptions_invoices"
  add_foreign_key "app_subscriptions_invoices", "app_subscriptions_restaurant_plans"
  add_foreign_key "app_subscriptions_invoices", "restaurants"
  add_foreign_key "app_subscriptions_restaurant_plans", "app_subscriptions_plans"
  add_foreign_key "app_subscriptions_restaurant_plans", "restaurants"
  add_foreign_key "bank_details", "restaurants"
  add_foreign_key "channel_integrations", "restaurants"
  add_foreign_key "combo_items", "combos"
  add_foreign_key "combos", "locations"
  add_foreign_key "combos", "restaurants"
  add_foreign_key "cuisines_restaurants", "cuisines"
  add_foreign_key "cuisines_restaurants", "restaurants"
  add_foreign_key "day_audits", "restaurants"
  add_foreign_key "day_audits", "team_members"
  add_foreign_key "day_audits", "users"
  add_foreign_key "delivery_addresses", "restaurants"
  add_foreign_key "delivery_addresses", "users"
  add_foreign_key "delivery_configurations", "restaurant_platforms"
  add_foreign_key "details_order_items", "combo_items"
  add_foreign_key "devices", "users"
  add_foreign_key "firebase_devices", "users"
  add_foreign_key "fssai_details", "restaurants"
  add_foreign_key "gst_details", "restaurants"
  add_foreign_key "invoice_generators", "restaurants"
  add_foreign_key "locations", "currencies"
  add_foreign_key "menu_assistance_requests", "locations"
  add_foreign_key "menu_categories", "restaurants"
  add_foreign_key "menu_items", "menu_categories"
  add_foreign_key "menu_items", "printers"
  add_foreign_key "menu_items", "restaurants"
  add_foreign_key "meta_app_tokens", "locations"
  add_foreign_key "order_activities", "orders"
  add_foreign_key "order_activities", "users"
  add_foreign_key "order_items", "menu_items"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_payments", "orders"
  add_foreign_key "orders", "day_audits"
  add_foreign_key "orders", "restaurants"
  add_foreign_key "orders", "team_members"
  add_foreign_key "orders", "users"
  add_foreign_key "orders", "whatsapp_customers"
  add_foreign_key "orders", "whatsapp_sessions"
  add_foreign_key "point_of_contacts", "restaurants"
  add_foreign_key "price_infos", "restaurants"
  add_foreign_key "printers", "restaurants"
  add_foreign_key "product_sales", "day_audits"
  add_foreign_key "restaurant_availability_events", "restaurants"
  add_foreign_key "restaurant_feedbacks", "restaurants"
  add_foreign_key "restaurant_feedbacks", "users"
  add_foreign_key "restaurant_platforms", "platforms"
  add_foreign_key "restaurant_platforms", "restaurants"
  add_foreign_key "restaurant_settlements", "restaurants"
  add_foreign_key "sales_summaries", "day_audits"
  add_foreign_key "settings", "restaurants"
  add_foreign_key "settlements", "restaurant_settlements"
  add_foreign_key "settlements", "restaurants"
  add_foreign_key "shortcut_sequences", "restaurants"
  add_foreign_key "store_carts", "whatsapp_addresses"
  add_foreign_key "store_carts", "whatsapp_orders"
  add_foreign_key "store_login_tokens", "restaurants"
  add_foreign_key "store_login_tokens", "whatsapp_customers"
  add_foreign_key "surveys", "locations"
  add_foreign_key "suspicious_actions", "orders"
  add_foreign_key "suspicious_actions", "restaurants"
  add_foreign_key "suspicious_actions", "users"
  add_foreign_key "team_members", "locations"
  add_foreign_key "token_generators", "restaurants"
  add_foreign_key "trashes", "restaurants"
  add_foreign_key "whatsapp_messages", "whatsapp_sessions"
  add_foreign_key "whatsapp_orders", "restaurants"
  add_foreign_key "whatsapp_payment_provider_orders", "whatsapp_orders"
  add_foreign_key "whatsapp_sessions", "restaurants"
  add_foreign_key "whatsapp_sessions", "whatsapp_customers"
  add_foreign_key "working_days", "restaurants"
  add_foreign_key "zomato_categories", "locations"
  add_foreign_key "zomato_categories", "restaurants"
  add_foreign_key "zomato_category_schedules", "zomato_categories"
  add_foreign_key "zomato_charge_taxes", "zomato_charges"
  add_foreign_key "zomato_charges", "restaurants"
  add_foreign_key "zomato_groups", "restaurants"
  add_foreign_key "zomato_item_charges", "zomato_items"
  add_foreign_key "zomato_item_taxes", "zomato_items"
  add_foreign_key "zomato_items", "locations"
  add_foreign_key "zomato_items", "printers"
  add_foreign_key "zomato_items", "restaurants"
  add_foreign_key "zomato_items", "zomato_categories"
  add_foreign_key "zomato_items", "zomato_subcategories"
  add_foreign_key "zomato_schedule_time_slots", "zomato_category_schedules", column: "zomato_category_schedules_id"
  add_foreign_key "zomato_subcategories", "zomato_categories"
  add_foreign_key "zomato_taxes", "restaurants"
  add_foreign_key "zomato_tier_wise_values", "zomato_charges"
  add_foreign_key "zomato_timings", "zomato_restaurant_offers"
end
