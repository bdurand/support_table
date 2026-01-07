# frozen_string_literal: true

require "spec_helper"

RSpec.describe SupportTable do
  describe "sync_all! discovery" do
    it "discovers support table models to load with autoloading" do
      expect(Status.count).to eq 6
      expect(Status::Group.count).to eq 3
      expect(NonStandardDataFile.count).to eq 0

      SupportTable.sync_all!
      expect(Status.count).to eq 6
      expect(Status::Group.count).to eq 3
      expect(NonStandardDataFile.count).to eq 2
    end
  end

  describe "key_attribute" do
    it "uses the primary key by default" do
      expect(Status.support_table_key_attribute).to eq "id"
    end

    it "can specify a key attribute" do
      expect(Status::Group.support_table_key_attribute).to eq "name"
    end
  end

  describe "data_file" do
    it "detects the default data file" do
      expect(Status.support_table_data).to eq YAML.load_file(File.join(__dir__, "data", "statuses.yml")).values
      expect(Status::Group.support_table_data).to eq YAML.load_file(File.join(__dir__, "data", "status/groups.yml")).values
    end

    it "can specify data files" do
      expect(NonStandardDataFile.support_table_data).to eq YAML.load_file(File.join(__dir__, "data", "non_standard.yml"))
    end

    it "has no data if the data file does not exist" do
      expect(NoDataFile.support_table_data).to eq []
    end

    it "is nil if the table doesn't exist" do
      expect(NoTable.support_table_data).to eq []
    end
  end

  describe "attribute_helpers" do
    it "has helpers for the key attribute by default" do
      expect(Status::Group.draft_name).to eq "Draft"
      expect(Status::Group.active_name).to eq "Active"
    end

    it "adds additional helper methods" do
      expect(Status::Group.draft_description).to eq "Non-live statuses"
      expect(Status::Group.closed_description).to eq "Terminal statuses"
    end
  end

  describe "cache_by" do
    it "includes the key attribute" do
      expect(Status::Group.support_table_cache_by_attributes.collect(&:first)).to include(["name"])
    end

    it "includes id by default" do
      expect(Status::Group.support_table_cache_by_attributes.collect(&:first)).to include(["id"])
    end

    it "can specify additional fields to cache by" do
      expect(Status::Group.support_table_cache_by_attributes.collect(&:first)).to include(["code"])
    end

    it "can composite key caching with the cache_by method" do
      expect(CompositeKey.support_table_cache_by_attributes.collect(&:first)).to include(["group", "name"])
    end
  end

  describe "cache" do
    it "uses an in-memory cache by default" do
      expect(Status.send(:support_table_cache_impl)).to be_a(SupportTableCache::MemoryCache)
    end

    it "can be overridden" do
      expect(Status::Group.send(:support_table_cache_impl)).to be_a(SupportTableCache::MemoryCache)
    end

    it "can be turned off" do
      expect(NotCached.support_table_cache_by_attributes).to eq []
    end
  end

  describe "ttl" do
    it "is nil by default" do
      expect(Status.support_table_cache_ttl).to eq nil
    end

    it "can set a ttl for the cache" do
      expect(Status::Group.support_table_cache_ttl).to eq 1.minute
    end
  end
end
