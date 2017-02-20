defmodule Mix.Tasks.CreateUser do
  use Mix.Task
  import Mix.Ecto

  # TODO: Allow specifying a specific changeset function to use 
  # TODO: Custom switches and aliases?  Dynamically determine switches and aliases
  # or dynamically prompt for required info like django create_user does?

  @switches  [first_name: :string, last_name: :string, email: :string,
              password: :string, is_active: :boolean]
  @aliases [f: :first_name, l: :last_name, e: :email, a: :is_active, p: :password]
  @shortdoc "Creates a User in the database"
  def run(args) do
    # Might be a better way, buyt this seems to work
    # This lets a config specify a specific ecto repo to use
    # otherwise grabs the first one specified in the phoenix app's config
    # Should be able to do this for user model as well
    repo = Application.get_env(:phoenix_users,
                               :ecto_repo,
                               Enum.at(Mix.Ecto.parse_repo(args), 0))
    ensure_started(repo, [])
    #user = User.changeset(%{})
    {options, _, errors} = OptionParser.parse(args, switches: @switches, aliases: @aliases)

    #TODO: prompt for any needed data which was not passed on command line

    #IO.inspect(options)
    #u = User.changeset(options)
    #IO.inspect(u)
    if !list_empty?(errors) do
      print_errors(errors)
    else
      create_user(options, repo)
    end
  end

  def list_empty?([]), do: true

  def list_empty?(list) when is_list(list) do
      false
  end

  def print_help() do
  end

  def print_errors(errors) do
    IO.inspect(errors)
  end

  def create_user(options, repo) do
    # if not for the password/password confirmation we could just use
    # Enum.into(options)
    # the !options[:is_active] makes a default to true even if not specified
    params = %{
      :first_name => options[:first_name],
      :last_name => options[:last_name],
      :email => options[:email],
      :is_activte => !options[:is_active],
      :password => options[:password],
      :password_confirmation => options[:password]
    }
    changeset = User.changeset(%User{}, params)

    case repo.insert(changeset) do
      {:ok, user} ->
        IO.puts("Created user #{user.email}!")
      {:error, changeset} ->
        IO.puts("The following errors occurred when creating the user:")
        for {field, {error, _}} <- changeset.errors do
          IO.puts IO.ANSI.format([:red, "#{field}:\n", :white, "\t#{error}"], true)
          #for error <- errors do
            #  IO.inspect error
            #end
        end
        #        IO.inspect(changeset)
    end
  end
end
