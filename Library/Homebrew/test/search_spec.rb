require "search"

describe Homebrew::Search do
  subject(:mod) { Object.new }

  before do
    mod.extend(described_class)
  end

  describe "#search_taps" do
    before do
      ENV.delete("HOMEBREW_NO_GITHUB_API")
    end

    it "does not raise if `HOMEBREW_NO_GITHUB_API` is set" do
      ENV["HOMEBREW_NO_GITHUB_API"] = "1"
      expect(mod.search_taps("some-formula")).to match([[], []])
    end

    it "does not raise if the network fails" do
      allow(GitHub).to receive(:open_api).and_raise(GitHub::Error)

      expect(mod.search_taps("some-formula"))
        .to match([[], []])
    end

    it "returns Formulae and Casks separately" do
      json_response = {
        "items" => [
          {
            "path" => "Formula/some-formula.rb",
            "repository" => {
              "full_name" => "Homebrew/homebrew-foo",
            },
          },
          {
            "path" => "Casks/some-cask.rb",
            "repository" => {
              "full_name" => "Homebrew/homebrew-bar",
            },
          },
        ],
      }

      allow(GitHub).to receive(:open_api).and_yield(json_response)

      expect(mod.search_taps("some-formula"))
        .to match([["homebrew/foo/some-formula"], ["homebrew/bar/some-cask"]])
    end
  end

  describe "#simplify_string" do
    it "simplifies a query with dashes" do
      expect(mod.query_regexp("que-ry")).to eq(/query/i)
    end

    it "simplifies a query with @ symbols" do
      expect(mod.query_regexp("query@1")).to eq(/query1/i)
    end
  end

  describe "#query_regexp" do
    it "correctly parses a regex query" do
      expect(mod.query_regexp("/^query$/")).to eq(/^query$/)
    end

    it "correctly converts a query string to a regex" do
      expect(mod.query_regexp("query")).to eq(/query/i)
    end

    it "simplifies a query with special symbols" do
      expect(mod.query_regexp("que-ry")).to eq(/query/i)
    end

    it "raises an error if the query is an invalid regex" do
      expect { mod.query_regexp("/+/") }.to raise_error(/not a valid regex/)
    end
  end
end
