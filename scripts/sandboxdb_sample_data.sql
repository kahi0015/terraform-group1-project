USE sandboxdb;

-- Adjust azure_resource_id and storage_uri to the real Azure resources

-- 1. Users
INSERT INTO user (email, display_name, is_active)
VALUES 
('johnsmith@example.com', 'John Smith', TRUE),
('joedoe@example.com', 'Joe Doe', TRUE),
('sandrataundra@example.com', 'Sandra Taundra', TRUE);

-- 2. Sandboxes
INSERT INTO sandbox (name, state, region)
VALUES
('DataSandbox1', 'active', 'eastus'),
('DataSandbox2', 'active', 'eastus');

-- 3. Sandbox_User (M:N link)
INSERT INTO sandbox_user (user_id, sandbox_id, role)
VALUES
(1, 1, 'owner'),
(2, 1, 'contributor'),
(3, 2, 'owner');

-- 4. Datasets
INSERT INTO dataset (sandbox_id, uploaded_by, name, storage_uri, size_bytes)
VALUES
(1, 1, 'SalesData', 'https://storageaccount.blob.core.windows.net/data/sales.csv', 102400),
(2, 3, 'MarketingData', 'https://storageaccount.blob.core.windows.net/data/marketing.csv', 204800);

-- 5. Analysis Sessions
INSERT INTO analysis_session (sandbox_id, started_by, tool)
VALUES
(1, 1, 'Python Jupyter'),
(2, 3, 'RStudio');

-- 6. Results
INSERT INTO result (session_id, type, storage_uri)
VALUES
(1, 'CSV', 'https://storageaccount.blob.core.windows.net/results/sales_result.csv'),
(2, 'JSON', 'https://storageaccount.blob.core.windows.net/results/marketing_result.json');

-- 7. Usage Logs
INSERT INTO usage_log (sandbox_id, at, cpu_cores, ram_gb, storage_gb, est_cost, message)
VALUES
(1, NOW(), 2, 4, 10, 0.15, 'Initial test run'),
(2, NOW(), 1, 2, 5, 0.08, 'Initial test run');

-- 8. Provision Runs
INSERT INTO provision_run (sandbox_id, action, status, tf_version)
VALUES
(1, 'apply', 'success', '1.5.9'),
(2, 'apply', 'success', '1.5.9');

-- 9. Sandbox Resources
INSERT INTO sandbox_resource (sandbox_id, run_id, kind, azure_resource_id, name, state, sku)
VALUES
(1, 1, 'VM', '/subscriptions/.../resourceGroups/.../providers/Microsoft.Compute/virtualMachines/vm1', 'vm1', 'running', 'Standard_B2s'),
(2, 2, 'MySQL', '/subscriptions/.../resourceGroups/.../providers/Microsoft.DBforMySQL/flexibleServers/mysql2', 'mysql2', 'ready', 'B_Standard_B1ms');
