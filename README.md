# Deploying SQL Server on Azure

This project demonstrates how to deploy a secure, private Microsoft Azure SQL Server instance using Terraform.

The deployment provisions a fully managed Azure SQL Server with public network access disabled, integrated into a custom virtual network and secured with a Private DNS Zone for internal name resolution. Additionally, the project provisions a lightweight Ubuntu virtual machine that runs [Adminer](https://www.adminer.org/), a browser-based SQL client, allowing private, browser-accessible interaction with the SQL Server database.

As part of the configuration, we deploy the [Pagila-SQLServer](https://github.com/mamonaco1973/pagila-sqlserver) sample dataset—a fictional DVD rental database—to showcase real-world querying and administration in a private cloud context. This solution is ideal for developers and teams looking to build secure, internal-facing applications without exposing SQL Server to the public internet.

![diagram](azure-sqlserver.png)

## What You'll Learn

- How to deploy a fully private Azure SQL Server using Terraform
- How to configure a custom virtual network, subnet, and Private DNS Zone for secure, internal connectivity
- How to provision a VM running `Adminer` for private browser-based database access
- Best practices for securing Azure-managed SQL Servers with private endpoints and infrastructure-as-code

## Overview of Azure SQL Database


## Prerequisites

* [An Azure Account](https://portal.azure.com/)
* [Install AZ CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) 
* [Install Latest Terraform](https://developer.hashicorp.com/terraform/install)

If this is your first time watching our content, we recommend starting with this video: [Azure + Terraform: Easy Setup](https://youtu.be/j4aRjgH5H8Q). It provides a step-by-step guide to properly configure Terraform and the AZ CLI.

## Download this Repository

```bash
git clone https://github.com/mamonaco1973/azure-sqlserver.git
cd azure-sqlserver
```

## Build the Code

Run [check_env](check_env.sh) then run [apply](apply.sh).

```bash
~/azure-sqlserver$ ./apply.sh
NOTE: Validating that required commands are found in your PATH.
NOTE: az is found in the current PATH.
NOTE: terraform is found in the current PATH.
NOTE: jq is found in the current PATH.
NOTE: All required commands are available.
NOTE: Validating that required environment variables are set.
NOTE: ARM_CLIENT_ID is set.
NOTE: ARM_CLIENT_SECRET is set.
NOTE: ARM_SUBSCRIPTION_ID is set.
NOTE: ARM_TENANT_ID is set.
NOTE: All required environment variables are set.
NOTE: Logging in to Azure using Service Principal...
NOTE: Successfully logged into Azure.
Initializing the backend...
Initializing provider plugins...
Terraform has been successfully initialized!
```

## Build Results

After applying the Terraform scripts, the following Azure resources will be created:

### Virtual Network & Subnet
- Virtual Network: `sqlserver-vnet`
  - Address space: `10.0.0.0/23`
- Subnet for SQL Server: `sqlserver-subnet`
  - Address range: `10.0.0.0/25`
- Network Security Group: `sqlserver-nsg`
  - Allows inbound SQL traffic on port 1433 from the Adminer VM

### Private DNS & Networking
- Private DNS Zone: `internal.sqlserver-zone.local`
  - Enables internal name resolution for the private SQL Server endpoint
- Private Endpoint:
  - Linked to the Azure SQL Server
  - Associated with the custom subnet and DNS zone

### Azure Key Vault
- Key Vault: `creds-kv-suffix`
  - Stores credentials securely
  - Access granted via Key Vault policy

### Azure SQL Server
- Server Name: Defined in variables
- Configuration:
  - Private access only (public network access disabled)
  - TLS 1.2 enforced for all connections
  - Admin credentials retrieved from Azure Key Vault
  - Preloaded with the [Pagila-SQLServer sample database](https://github.com/mamonaco1973/pagila-sqlserver)

### Virtual Machine (Adminer)
- VM Name: `adminer-vm`
  - Ubuntu-based VM to host `Adminer` client
  - Deployed in the same virtual network
  - Connected privately to the SQL Server
  - Configured to launch `Adminer` and expose a browser-based SQL Server UI

## Adminer Demo

[Adminer](https://www.adminer.org/) is a lightweight web-based SQL database management tool.

![adminer](adminer.png)
Query 1:
```sql
SELECT TOP 100                       -- Limit the number of rows returned to 100
    f.title AS film_title,           -- Select the 'title' column from the 'film' table and rename it to 'film_title'
    a.first_name + ' ' + a.last_name AS actor_name 
                                     -- Concatenate 'first_name' and 'last_name' from the 'actor' table with a space
                                     -- Alias the concatenated result as 'actor_name' for readability
FROM
    film f                           -- Use the 'film' table as the primary dataset and alias it as 'f'
JOIN
    film_actor fa                    -- Join the linking table 'film_actor' that associates films with actors
    ON f.film_id = fa.film_id        -- Match rows where the film's unique ID equals the film_actor's film ID
JOIN
    actor a                          -- Join the 'actor' table to retrieve actor details
    ON fa.actor_id = a.actor_id      -- Match rows where the actor's unique ID equals the film_actor's actor ID
ORDER BY 
    f.title,                         -- Sort results by the film title in ascending alphabetical order
    actor_name;                      -- Within each film, sort the actor names alphabetically
```

Query 2:

```sql
SELECT TOP 100                               -- Limit the output to the first 100 rows returned
    f.title,                                 -- Select the 'title' column from the 'film' table
    STRING_AGG(a.first_name + ' ' + a.last_name, ', ') AS actor_names
                                             -- Use STRING_AGG to concatenate all actor names for each film
                                             -- Combine 'first_name' and 'last_name' separated by a space
                                             -- Separate multiple actor names in the aggregated string with a comma and a space
                                             -- Alias the resulting concatenated list as 'actor_names'
FROM
    film f                                   -- Use the 'film' table as the main dataset and alias it as 'f'
JOIN
    film_actor fa                            -- Join the linking table 'film_actor' to connect films and actors
    ON f.film_id = fa.film_id                -- Match rows where film IDs from both tables are equal
JOIN
    actor a                                  -- Join the 'actor' table to get actor details
    ON fa.actor_id = a.actor_id              -- Match rows where actor IDs from both tables are equal
GROUP BY
    f.title                                  -- Group the results by each film title so all associated actors are aggregated together
ORDER BY
    f.title;                                 -- Sort the output alphabetically by film title
```

