defmodule Mix.Tasks.CreateUser do
  use Mix.Task
  import Mix.Ecto

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
    # Seem to need both of these, ensure_repo and ensure_started
    ensure_repo(repo, [])
    ensure_started(repo, [])
    {options, _, errors} = OptionParser.parse(args, switches: @switches, aliases: @aliases)

    {:ok, user_model} = PhoenixUsers.get_user_model()

    required = PhoenixUsers.get_required_fields(user_model)
    # prompt for any missing required fields and add them to options
    options = options ++ for required_field <- required, not Keyword.has_key?(options, required_field) do
      # string to atom stuff here mucking things up
      x = IO.gets("#{humanize(required_field)}: ") |> String.trim()
      # assumping required_field is an atom already for now
      {required_field, x}
    end

    changeset_function = Keyword.get(options,
                                     :changeset,
                                     Application.get_env(:phoenix_users, :create_user_changset, "changeset"))
    {:ok, changeset_function} = get_changeset_function_atom(changeset_function)

    #TODO: check user_model and changeset_function for errors as well
    if !list_empty?(errors) do
      print_errors(errors)
    else
      create_user(options, repo, user_model, changeset_function)
    end
  end

  @doc """
  Takes the changeset function name as a parameter and returns
  the appropriate atom for it for use in apply/3
  """
  def get_changeset_function_atom(changeset_function) do
    cond do
      is_bitstring(changeset_function) ->
        {:ok, String.to_atom(changeset_function)}
      is_atom(changeset_function) ->
        {:ok, changeset_function}
      true ->
        {:error, changeset_function}
    end
  end

  @doc """
  Helper to test if a list is empty or not
  """
  def list_empty?([]), do: true
  def list_empty?(list) when is_list(list), do: false

  def print_help() do
  end

  def print_errors(errors) do
    IO.inspect(errors)
  end

  def create_user(options, repo, user_model, changset_function) do
    #convert options keyword list into map needed for changset, but make some assumptions for now
    # around is_active and  password
    params = Enum.into(options, %{})
      |> Map.put(:password, options[:password])
      |> Map.put(:password_confirmation, options[:password])
      |> Map.put(:is_active, !options[:is_active])
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

  def humanize(atom) when is_atom(atom) do
     humanize(Atom.to_string(atom))
  end
  
  def humanize(bin) when is_binary(bin) do
    bin =
      if String.ends_with?(bin, "_id") do
        binary_part(bin, 0, byte_size(bin) - 3)
      else
        bin
      end
      
    bin |> String.replace("_", " ") |> String.capitalize
  end
end
