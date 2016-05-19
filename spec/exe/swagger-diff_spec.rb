require 'spec_helper'

describe 'swagger-diff' do
  let(:changes) do
    '- new endpoints
  - delete /pets/{}
  - get /pets/{}
  - post /pets
- new request params
  - get /pets
    - new request param: tags (in: query, type: array)
    - new request param: limit (in: query, type: integer)
'
  end
  let(:differences) do
    '- missing endpoints
  - delete /pets/{}
  - get /pets/{}
  - post /pets
- incompatible request params
  - get /pets
    - missing request param: tags (in: query, type: array)
    - missing request param: limit (in: query, type: integer)
'
  end
  let(:help) do
    'Usage: swagger-diff [options] <old> <new>
    -c, --changes                    Generate a list of changes between <new>
                                     and <old>
    -i, --incompatibilities          Checks <new> for backwards-compatibility
                                     with <old>. If <new> is incompatible, a
                                     list of incompatibilities will be printed.
    -h, --help                       This message
    -v, --version                    Display the version
'
  end

  it 'prints help if no specs are specified' do
    expect { system('bundle exec exe/swagger-diff') }
      .to output(help).to_stdout_from_any_process
  end

  it 'prints changes' do
    expect do
      system('bundle exec exe/swagger-diff -c spec/fixtures/petstore.json ' \
             'spec/fixtures/petstore-with-external-docs.json')
    end.to output(changes).to_stdout_from_any_process
  end

  it 'prints incompatibilities' do
    expect do
      system('bundle exec exe/swagger-diff -i ' \
             'spec/fixtures/petstore-with-external-docs.json ' \
             'spec/fixtures/petstore.json')
    end.to output(differences).to_stdout_from_any_process
  end

  it 'prints incompatibilities if no options are specified' do
    expect do
      system('bundle exec exe/swagger-diff ' \
             'spec/fixtures/petstore-with-external-docs.json ' \
             'spec/fixtures/petstore.json')
    end.to output(differences).to_stdout_from_any_process
  end

  it 'prints help' do
    expect { system('bundle exec exe/swagger-diff -h') }
      .to output(help).to_stdout_from_any_process
  end

  it 'prints the version' do
    expect { system('bundle exec exe/swagger-diff -v') }
      .to output("#{Swagger::Diff::VERSION}\n").to_stdout_from_any_process
  end
end
