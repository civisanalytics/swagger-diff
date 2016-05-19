require 'spec_helper'

describe Swagger::Diff::Diff do
  let(:compat_diff) do
    Swagger::Diff::Diff.new('spec/fixtures/petstore.json',
                            'spec/fixtures/petstore-with-external-docs.json')
  end
  let(:incompat_diff) do
    Swagger::Diff::Diff.new('spec/fixtures/dummy.v1.json',
                            'spec/fixtures/dummy.v2.json')
  end

  it '.initialize' do
    expect { compat_diff }.not_to raise_error
  end

  describe '#compatible?' do
    it { expect(compat_diff.compatible?).to be true }
    it { expect(incompat_diff.compatible?).to be false }
  end

  it '#incompatibilities' do
    expect(incompat_diff.incompatibilities)
      .to eq(endpoints: ['post /b/', 'put /a/{}'],
             request_params: {
               'get /a/' => ['missing request param: limit (in: query, type: integer)'],
               'post /a/' => ['new required request param: extra'],
               'patch /a/{}' => [
                 'missing request param: name (in: body, type: ["string", "null"])',
                 'missing request param: obj/thing (in: body, type: integer)',
                 'missing request param: str (in: body, type: string)'
               ],
               'put /b/{}' => ['new required request param: extra'],
               'post /c/' => ['new required request param: existing/b']
             },
             response_attributes: {
               'post /a/' => ['missing attribute from 200 response: description (in: body, type: string)'],
               'get /a/{}' => ['missing attribute from 200 response: description (in: body, type: string)'],
               'patch /a/{}' => ['missing attribute from 200 response: obj/thing (in: body, type: integer)',
                                 'missing attribute from 200 response: objs[]/thing (in: body, type: integer)'],
               'put /b/{}' => ['missing attribute from 200 response: description (in: body, type: string)'],
               'get /c/' => ['missing attribute from 200 response: []/name (in: body, type: string)',
                             'missing 201 response']
             })
  end

  describe '#incompatibilities_message' do
    let(:incompat_msg) do
      '- missing endpoints
  - post /b/
  - put /a/{}
- incompatible request params
  - get /a/
    - missing request param: limit (in: query, type: integer)
  - patch /a/{}
    - missing request param: name (in: body, type: ["string", "null"])
    - missing request param: obj/thing (in: body, type: integer)
    - missing request param: str (in: body, type: string)
  - post /a/
    - new required request param: extra
  - post /c/
    - new required request param: existing/b
  - put /b/{}
    - new required request param: extra
- incompatible response attributes
  - get /a/{}
    - missing attribute from 200 response: description (in: body, type: string)
  - get /c/
    - missing attribute from 200 response: []/name (in: body, type: string)
    - missing 201 response
  - patch /a/{}
    - missing attribute from 200 response: obj/thing (in: body, type: integer)
    - missing attribute from 200 response: objs[]/thing (in: body, type: integer)
  - post /a/
    - missing attribute from 200 response: description (in: body, type: string)
  - put /b/{}
    - missing attribute from 200 response: description (in: body, type: string)
'
    end

    it { expect(compat_diff.incompatibilities_message).to eq('') }
    it { expect(incompat_diff.incompatibilities_message).to eq(incompat_msg) }
  end

  describe '#missing_endpoints' do
    it { expect(compat_diff.send(:missing_endpoints)).to eq(Set.new) }

    it do
      expect(incompat_diff.send(:missing_endpoints))
        .to eq(Set.new(['put /a/{}', 'post /b/']))
    end
  end

  describe '#endpoints_compatible?' do
    it { expect(compat_diff.send(:endpoints_compatible?)).to be true }
    it { expect(incompat_diff.send(:endpoints_compatible?)).to be false }
  end

  describe '#requests_compatible?' do
    it { expect(compat_diff.send(:requests_compatible?)).to be true }
    it { expect(incompat_diff.send(:requests_compatible?)).to be false }
  end

  describe '#responses_compatible?' do
    it { expect(compat_diff.send(:responses_compatible?)).to be true }
    it { expect(incompat_diff.send(:responses_compatible?)).to be false }
  end
end
