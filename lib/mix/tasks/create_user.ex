defmodule Mix.Tasks.CreateUser do
  use Mix.Task
  import Mix.Ecto

  # TODO: Allow specifying a specific changeset function to use 
  # TODO: Custom switches and aliases?  Dynamically determine switches and aliases
  # or dynamically prompt for required info like django create_user does?

  @switches  [first_name: :string, last_name: :string, email: :string,
              password: :string, is_active: :boolean, model: :string, changeset: :string]
  @aliases [f: :first_name, l: :last_name, e: :email, a: :is_active, p: :password]
  @shortdoc "Creates a User in the database"
  def run(args) do
    # Might be a better way, buyt this seems to work
    # This lets a config specify a specific ecto repo to use
    # otherwise grabs the first one specified in the phoenix app's config
    # TODO: handle string here and allow string as well as atom/module name
    # as was done for user model and changeset
    repo = Application.get_env(:phoenix_users,
                               :ecto_repo,
                               Enum.at(Mix.Ecto.parse_repo(args), 0))
    ensure_started(repo, [])
    #user = User.changeset(%{})
    {options, _, errors} = OptionParser.parse(args, switches: @switches, aliases: @aliases)

    user_model = Map.get(options,
                         :model,
                         Application.get_env(:phoenix_users, :user_model))
    # TODO: Handle error returns with these
    {:ok, user_model} = get_atom(user_model)

    changeset_function = Map.get(options,
                                 :changeset,
                                 Application.get_env(:phoenix_users, :create_user_changset, "changeset"))
    {:ok, changeset_function} = get_atom(changeset_function)
    #user_model = Application.get_env(:phoenix_users, :user_model)

    #TODO: prompt for any needed data which was not passed on command line

    #IO.inspect(options)
    #u = user_model.changeset(options)
    #IO.inspect(u)

    #TODO: check user_model and changeset_function for errors as well
    if !list_empty?(errors) do
      print_errors(errors)
    else
      create_user(options, repo, user_model, changeset_function)
    end
  end

  @doc """
  Take an atom or bitstring and return the atom representation and status.
  """
  def get_atom(source) do
    cond do
      is_bitstring(source) ->
        {:ok, Module.concat(String.split(source, "."))}
      is_atom(source) ->
        {:ok, source}
      true ->
        {:error, source}
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

  def create_user(options, repo, user_model, changset_function) do
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
    changeset = apply(user_model, changset_function, [struct(user_model), params])
    #changeset = User.changeset(%User{}, params)

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
