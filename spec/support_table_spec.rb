# frozen_string_literal: true

require_relative "spec_helper"

describe SupportTable do
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
      expect(Status::Group.support_table_key_attribute).to eq :name
    end

    it "is nil if the table doesn't exist" do
      expect(NoTable.support_table_key_attribute).to eq nil
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

  describe "cache_by" do
    it "includes the primary key" do
      expect(Status.support_table_cache_by_attributes.collect(&:first)).to include(["id"])
    end

    it "automatically uses unique indexes" do
      expect(Status.support_table_cache_by_attributes.collect(&:first)).to include(["name"])
    end

    it "does not use unique indexes with a where clause" do
      expect(DeletableItem.support_table_cache_by_attributes.collect(&:first)).to eq([["id"]])
    end

    it "can specify the fields to cache by" do
      expect(Status::Group.support_table_cache_by_attributes.collect(&:first)).to include(["name"])
    end

    it "is empty if the table doesn't exist" do
      expect(NoTable.support_table_cache_by_attributes).to eq nil
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
end
