# Copyright (c) .NET Foundation. All rights reserved.
# Licensed under the MIT license. See LICENSE file in the project root for full license information.


##
## Assigning a "DefaultValue" to a ParameterDescription will result in emitting this parameter when
## writing out a default builder declaration.
##
## Setting IsRequired to $true will require the attribute to be set on all declarations in config.
##
## Parameters that are not in the allowed list will be dropped from config declarations.
##
Add-Type @"
	using System;

	public class ValueMap {
		public string OriginalValue;
		public string NewValue;
	}

	public class ParameterDescription {
		public string Name;
		public string DefaultValue;
		public bool IsRequired;
		public string MigrateTo;
		public ValueMap[] ValueMigration;
		public bool IsObsolete;
		public string[] ObsoleteValues;
	}

	public class BuilderDescription {
		public string TypeName;
		public string Assembly;
		public string Version;
		public string DefaultName;
		public ParameterDescription[] AllowedParameters;
	}
"@

$keyValueCommonParameters = @(
		[ParameterDescription]@{ Name="mode"; IsRequired=$false; MigrateTo="mode";
			ValueMigration=@(
				[ValueMap]@{ OriginalValue="Expand"; NewValue="Token"}
			) },
		[ParameterDescription]@{ Name="prefix"; IsRequired=$false },
		[ParameterDescription]@{ Name="stripPrefix"; IsRequired=$false },
		[ParameterDescription]@{ Name="tokenPattern"; IsRequired=$false },
		[ParameterDescription]@{ Name="escapeExpandedValues"; IsRequired=$false },
		[ParameterDescription]@{ Name="charMap"; IsRequired=$false },
		[ParameterDescription]@{ Name="enabled"; IsRequired=$false },
		[ParameterDescription]@{ Name="optional"; IsRequired=$false; MigrateTo="enabled";
			ValueMigration=@(
				[ValueMap]@{ OriginalValue="true"; NewValue="optional"},
				[ValueMap]@{ OriginalValue="false"; NewValue="enabled"}
			) }
		);

function CommonInstall($builderDescription) {
	##### Update/Rehydrate config declarations #####
	$config = ReadConfigFile
	$rehydratedCount = RehydrateOldDeclarations $config $builderDescription
	$updatedCount = UpdateDeclarations $config $builderDescription
	if ($rehydratedCount -le 0) { AddDefaultDeclaration $config $builderDescription }
	SaveConfigFile $config
}

function CommonUninstall($builderType) {
	##### Dehydrate config declarations #####
	$config = ReadConfigFile
	DehydrateDeclarations $config $builderType | Out-Null
	SaveConfigFile $config
}

function GetConfigFileName() {
	# Try web.config first. Then fall back to app.config.
	$configFile = $project.ProjectItems | where { $_.Name -ieq "web.config" }
	if ($configFile -eq $null) { $configFile = $project.ProjectItems | where { $_.Name -ieq "app.config" } }
	$configPath = $configFile.Properties | where { $_.Name -ieq "LocalPath" }
    if ($configPath -eq $null) { $configPath = $configFile.Properties | where { $_.Name -ieq "FullPath" } }
	return $configPath.Value
}

function GetTempFileName() {
	$uname = $project.UniqueName
	if ([io.path]::IsPathRooted($uname)) { $uname = $project.Name }
	return [io.path]::Combine($env:TEMP, "Microsoft.Configuration.ConfigurationBuilders.KeyValueConfigBuilders.Temp", $uname + ".xml")
}

function ReadConfigFile() {
	$configFile = GetConfigFileName
	$configObj = @{ fileName = $configFile; xml = (Select-Xml -Path "$configFile" -XPath /).Node }
	$configObj.xml.PreserveWhitespace = $true
	return $configObj
}

function DehydrateDeclarations($config, $typeName) {
	$tempFile = GetTempFileName
	$count = 0

	if ([io.file]::Exists($tempFile)) {
		$xml = (Select-Xml -Path "$tempFile" -XPath /).Node
	} else {
		$xml = New-Object System.Xml.XmlDocument
		$xml.PreserveWhitespace = $true
		$xml.AppendChild($xml.CreateElement("driedDeclarations")) | Out-Null
	}

	foreach ($rec in $config.xml.configuration.configBuilders.builders.add  | where { IsSameType $_.type $typeName }) {
		# Remove records from config.
		$config.xml.configuration.configBuilders.builders.RemoveChild($rec) | Out-Null

		# Add the record to the temp stash. Don't worry about duplicates.
		AppendBuilderNode $xml.ImportNode($rec, $true) $xml.DocumentElement | Out-Null
		$count++
	}

	# Save the dehydrated declarations
	$tmpFolder = Split-Path $tempFile
	md -Force $tmpFolder | Out-Null
	$xml.Save($tempFile) | Out-Null
	return $count
}

function RehydrateOldDeclarations($config, $builderDescription) {
	$tempFile = GetTempFileName
	if (![io.file]::Exists($tempFile)) { return 0 }

	$count = 0
	$xml = (Select-Xml -Path "$tempFile" -XPath /).Node
	$xml.PreserveWhitespace = $true

	foreach($rec in $xml.driedDeclarations.add | where { IsSameType $_.type ($builderDescription.TypeName + "," + $builderDescription.Assembly) }) {
		# Remove records that match type, even if we don't end up rehydrating them.
		$xml.driedDeclarations.RemoveChild($rec) | Out-Null

		# Skip if an existing record of the same name already exists.
		$existingRecord = $config.xml.configuration.configBuilders.builders.add | where { $_.name -eq $rec.name }
		if ($existingRecord -ne $null) { continue }

		# Bring the record back to life
		AppendBuilderNode $config.xml.ImportNode($rec, $true) $config.xml.configuration.configBuilders.builders | Out-Null
		$count++
		Write-Host "Restored configBuilder '$($rec.name)'."
	}

	# Make dried record removal permanent
	$xml.Save($tempFile) | Out-Null

	return $count
}

function UpdateDeclarations($config, $builderDescription) {
	$count = 0

	foreach ($builder in $config.xml.configuration.configBuilders.builders.add | where { IsSameType $_.type ($builderDescription.TypeName + "," + $builderDescription.Assembly) }) {

		$failed = $false

		# Migrate parameters that have changed
		foreach ($p in $builderDescription.AllowedParameters | where { $_.MigrateTo -ne $null }) {
			if ($builder.($p.Name) -ne $null) {
				$oldvalue = $builder.($p.Name)
				$newvalue = ($p.ValueMigration | where { $_.OriginalValue -eq $oldvalue } | select -First 1 ).NewValue
				if ($newvalue -eq $null) { $newvalue = $oldvalue }
				$builder.RemoveAttribute($p.Name) | Out-Null
				$builder.SetAttribute($p.MigrateTo, $newvalue) | Out-Null
				Write-Host "Migrated '$($p.Name):$($oldvalue)' to '$($p.MigrateTo):$($newvalue)' for configBuilder '$($builder.name)'"
			}
		}

		# Add default parameters if they are required and not already present
		foreach ($p in $builderDescription.AllowedParameters | where { $_.IsRequired -eq $true }) {
			if ($builder.($p.Name) -eq $null) {
				if ($p.DefaultValue -eq $null) {
					Write-Warning "Failed to add parameter to '$($builder.name)' configBuilder: '$($p.Name)' is required, but does not have a default value."
					$failed = $true
				}
				$builder.SetAttribute($p.Name, $p.DefaultValue) | Out-Null
				Write-Host "Added default value for parameter '$($p.Name)' to configBuilder '$($builder.name)'"
			}
		}

		# Finally, update type. And do so with remove/add so the 'type' parameter get put at the end
		$builder.RemoveAttribute("type") | Out-Null
		$builder.SetAttribute("type", "$($builderDescription.TypeName), $($builderDescription.Assembly), Version=$($builderDescription.Version), Culture=neutral, PublicKeyToken=31bf3856ad364e35") | Out-Null

		# Check for unknown parameters
		foreach ($attr in $builder.Attributes | where { ($_.Name -ne "name") -and ($_.Name -ne "type") }) {
			if (($builderDescription.AllowedParameters | where { $_.Name -ceq $attr.Name }) -eq $null) {
				# Leave it alone, but spit out a warning?
				Write-Warning "The parameter '$($attr.Name)' on configBuilder '$($builder.name)' is unknown and may cause errors at runtime."
			}
		}

		# Warn about any obsolete settings
		foreach ($p in $builderDescription.AllowedParameters | where { $_.IsObsolete -eq $true }) {
			if ($builder.($p.Name) -ne $null) {
				Write-Warning "The parameter '$($p.Name)' on '$($builder.name)' configBuilder is obsolete. Please consider alternative configurations."
			}
		}
		foreach ($p in $builderDescription.AllowedParameters | where { $_.ObsoleteValues -ne $null -and $_.ObsoleteValues.Count -gt 0 }) {
			if ($builder.($p.Name) -ne $null -and $p.ObsoleteValues.Contains($builder.($p.Name))) {
				Write-Warning "The value of parameter '$($p.Name)' on '$($builder.name)' configBuilder is obsolete. Please consider alternative configurations."
			}
		}

		# Count the existing declaration as updated
		if ($failed -ne $true) { $count++ }
	}

	return $count
}

function AddDefaultDeclaration($config, $builderDescription) {
	$dd = $config.xml.CreateElement("add")

	# name first
	$dd.SetAttribute("name", $builderDescription.DefaultName) | Out-Null

	# everything else in the middle
	foreach ($p in $builderDescription.AllowedParameters) {
		if ($p.IsRequired -and ($p.DefaultValue -eq $null)) {
			Write-Host "Failed to add default declaration for $($builderDescription.TypeName): '$($p.Name)' is required, but does not have a default value."
			return
		}

		if ($p.DefaultValue -ne $null) {
			$dd.SetAttribute($p.Name, $p.DefaultValue) | Out-Null
		}
	}

	# type last
	$dd.SetAttribute("type", "$($builderDescription.TypeName), $($builderDescription.Assembly), Version=$($builderDescription.Version), Culture=neutral, PublicKeyToken=31bf3856ad364e35") | Out-Null

	AppendBuilderNode $dd $config.xml.configuration.configBuilders.builders | Out-Null
	Write-Host "Added default configBuilder '$($dd.name)'."
}

function AppendBuilderNode($builder, $parent, $indentLevel = 3) {
	$lastSibling = $parent.ChildNodes | where { $_ -isnot [System.Xml.XmlWhitespace] } | select -Last 1
	if ($lastSibling -ne $null) {
		# If not the first child, then copy the whitespace convention of the existing child
		$ws = "";
		$prev = $lastSibling.PreviousSibling | where { $_ -is [System.Xml.XmlWhitespace] }
		while ($prev -ne $null) {
			$ws = $prev.data + $ws
			$prev = $prev.PreviousSibling | where { $_ -is [System.Xml.XmlWhitespace] }
		}
		$parent.InsertAfter($builder, $lastSibling) | Out-Null
		if ($ws.length -gt 0) { $parent.InsertAfter($parent.OwnerDocument.CreateWhitespace($ws), $lastSibling) | Out-Null }
		return
	}

	# Add on a new line with indents. Make sure there is no existing whitespace mucking this up.
	foreach ($exws in $parent.ChildNodes | where { $_ -is [System.Xml.XmlWhitespace] }) { $parent.RemoveChild($exws) | Out-Null }
	$parent.AppendChild($parent.OwnerDocument.CreateWhitespace("`r`n")) | Out-Null
	$parent.AppendChild($parent.OwnerDocument.CreateWhitespace("  " * $indentLevel)) | Out-Null
	$parent.AppendChild($builder) | Out-Null
	$parent.AppendChild($parent.OwnerDocument.CreateWhitespace("`r`n")) | Out-Null
	$parent.AppendChild($parent.OwnerDocument.CreateWhitespace("  " * ($indentLevel - 1))) | Out-Null
}

function SaveConfigFile($config) {
	$config.xml.Save($config.fileName) | Out-Null
}

function IsSameType($typeString1, $typeString2) {

	if (($typeString1 -eq $null) -or ($typeString2 -eq $null)) { return $false }

	# First check the type
	$t1 = $typeString1.Split(',')[0].Trim()
	$t2 = $typeString2.Split(',')[0].Trim()
	if ($t1 -cne $t2) { return $false }

	# Then check for assembly match if possible
	$a1 = $typeString1.Split(',')[1]
	$a2 = $typeString2.Split(',')[1]
	if (($a1 -ne $null) -and ($a2 -ne $null)) {
		return ($a1.Trim() -eq $a2.Trim())
	}

	# Don't care about assembly. Match is good.
	return $true
}

# SIG # Begin signature block
# MIInoQYJKoZIhvcNAQcCoIInkjCCJ44CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDKEEH4+pt4RRI+
# 2rCsAuPD1adca5ZHG1Kk4Yg7OczfCqCCDYEwggX/MIID56ADAgECAhMzAAACUosz
# qviV8znbAAAAAAJSMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMjEwOTAyMTgzMjU5WhcNMjIwOTAxMTgzMjU5WjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQDQ5M+Ps/X7BNuv5B/0I6uoDwj0NJOo1KrVQqO7ggRXccklyTrWL4xMShjIou2I
# sbYnF67wXzVAq5Om4oe+LfzSDOzjcb6ms00gBo0OQaqwQ1BijyJ7NvDf80I1fW9O
# L76Kt0Wpc2zrGhzcHdb7upPrvxvSNNUvxK3sgw7YTt31410vpEp8yfBEl/hd8ZzA
# v47DCgJ5j1zm295s1RVZHNp6MoiQFVOECm4AwK2l28i+YER1JO4IplTH44uvzX9o
# RnJHaMvWzZEpozPy4jNO2DDqbcNs4zh7AWMhE1PWFVA+CHI/En5nASvCvLmuR/t8
# q4bc8XR8QIZJQSp+2U6m2ldNAgMBAAGjggF+MIIBejAfBgNVHSUEGDAWBgorBgEE
# AYI3TAgBBggrBgEFBQcDAzAdBgNVHQ4EFgQUNZJaEUGL2Guwt7ZOAu4efEYXedEw
# UAYDVR0RBEkwR6RFMEMxKTAnBgNVBAsTIE1pY3Jvc29mdCBPcGVyYXRpb25zIFB1
# ZXJ0byBSaWNvMRYwFAYDVQQFEw0yMzAwMTIrNDY3NTk3MB8GA1UdIwQYMBaAFEhu
# ZOVQBdOCqhc3NyK1bajKdQKVMFQGA1UdHwRNMEswSaBHoEWGQ2h0dHA6Ly93d3cu
# bWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY0NvZFNpZ1BDQTIwMTFfMjAxMS0w
# Ny0wOC5jcmwwYQYIKwYBBQUHAQEEVTBTMFEGCCsGAQUFBzAChkVodHRwOi8vd3d3
# Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRzL01pY0NvZFNpZ1BDQTIwMTFfMjAx
# MS0wNy0wOC5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG9w0BAQsFAAOCAgEAFkk3
# uSxkTEBh1NtAl7BivIEsAWdgX1qZ+EdZMYbQKasY6IhSLXRMxF1B3OKdR9K/kccp
# kvNcGl8D7YyYS4mhCUMBR+VLrg3f8PUj38A9V5aiY2/Jok7WZFOAmjPRNNGnyeg7
# l0lTiThFqE+2aOs6+heegqAdelGgNJKRHLWRuhGKuLIw5lkgx9Ky+QvZrn/Ddi8u
# TIgWKp+MGG8xY6PBvvjgt9jQShlnPrZ3UY8Bvwy6rynhXBaV0V0TTL0gEx7eh/K1
# o8Miaru6s/7FyqOLeUS4vTHh9TgBL5DtxCYurXbSBVtL1Fj44+Od/6cmC9mmvrti
# yG709Y3Rd3YdJj2f3GJq7Y7KdWq0QYhatKhBeg4fxjhg0yut2g6aM1mxjNPrE48z
# 6HWCNGu9gMK5ZudldRw4a45Z06Aoktof0CqOyTErvq0YjoE4Xpa0+87T/PVUXNqf
# 7Y+qSU7+9LtLQuMYR4w3cSPjuNusvLf9gBnch5RqM7kaDtYWDgLyB42EfsxeMqwK
# WwA+TVi0HrWRqfSx2olbE56hJcEkMjOSKz3sRuupFCX3UroyYf52L+2iVTrda8XW
# esPG62Mnn3T8AuLfzeJFuAbfOSERx7IFZO92UPoXE1uEjL5skl1yTZB3MubgOA4F
# 8KoRNhviFAEST+nG8c8uIsbZeb08SeYQMqjVEmkwggd6MIIFYqADAgECAgphDpDS
# AAAAAAADMA0GCSqGSIb3DQEBCwUAMIGIMQswCQYDVQQGEwJVUzETMBEGA1UECBMK
# V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0
# IENvcnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQgUm9vdCBDZXJ0aWZpY2F0
# ZSBBdXRob3JpdHkgMjAxMTAeFw0xMTA3MDgyMDU5MDlaFw0yNjA3MDgyMTA5MDla
# MH4xCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdS
# ZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMT
# H01pY3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTEwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQCr8PpyEBwurdhuqoIQTTS68rZYIZ9CGypr6VpQqrgG
# OBoESbp/wwwe3TdrxhLYC/A4wpkGsMg51QEUMULTiQ15ZId+lGAkbK+eSZzpaF7S
# 35tTsgosw6/ZqSuuegmv15ZZymAaBelmdugyUiYSL+erCFDPs0S3XdjELgN1q2jz
# y23zOlyhFvRGuuA4ZKxuZDV4pqBjDy3TQJP4494HDdVceaVJKecNvqATd76UPe/7
# 4ytaEB9NViiienLgEjq3SV7Y7e1DkYPZe7J7hhvZPrGMXeiJT4Qa8qEvWeSQOy2u
# M1jFtz7+MtOzAz2xsq+SOH7SnYAs9U5WkSE1JcM5bmR/U7qcD60ZI4TL9LoDho33
# X/DQUr+MlIe8wCF0JV8YKLbMJyg4JZg5SjbPfLGSrhwjp6lm7GEfauEoSZ1fiOIl
# XdMhSz5SxLVXPyQD8NF6Wy/VI+NwXQ9RRnez+ADhvKwCgl/bwBWzvRvUVUvnOaEP
# 6SNJvBi4RHxF5MHDcnrgcuck379GmcXvwhxX24ON7E1JMKerjt/sW5+v/N2wZuLB
# l4F77dbtS+dJKacTKKanfWeA5opieF+yL4TXV5xcv3coKPHtbcMojyyPQDdPweGF
# RInECUzF1KVDL3SV9274eCBYLBNdYJWaPk8zhNqwiBfenk70lrC8RqBsmNLg1oiM
# CwIDAQABo4IB7TCCAekwEAYJKwYBBAGCNxUBBAMCAQAwHQYDVR0OBBYEFEhuZOVQ
# BdOCqhc3NyK1bajKdQKVMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMAsGA1Ud
# DwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFHItOgIxkEO5FAVO
# 4eqnxzHRI4k0MFoGA1UdHwRTMFEwT6BNoEuGSWh0dHA6Ly9jcmwubWljcm9zb2Z0
# LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY1Jvb0NlckF1dDIwMTFfMjAxMV8wM18y
# Mi5jcmwwXgYIKwYBBQUHAQEEUjBQME4GCCsGAQUFBzAChkJodHRwOi8vd3d3Lm1p
# Y3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY1Jvb0NlckF1dDIwMTFfMjAxMV8wM18y
# Mi5jcnQwgZ8GA1UdIASBlzCBlDCBkQYJKwYBBAGCNy4DMIGDMD8GCCsGAQUFBwIB
# FjNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2RvY3MvcHJpbWFyeWNw
# cy5odG0wQAYIKwYBBQUHAgIwNB4yIB0ATABlAGcAYQBsAF8AcABvAGwAaQBjAHkA
# XwBzAHQAYQB0AGUAbQBlAG4AdAAuIB0wDQYJKoZIhvcNAQELBQADggIBAGfyhqWY
# 4FR5Gi7T2HRnIpsLlhHhY5KZQpZ90nkMkMFlXy4sPvjDctFtg/6+P+gKyju/R6mj
# 82nbY78iNaWXXWWEkH2LRlBV2AySfNIaSxzzPEKLUtCw/WvjPgcuKZvmPRul1LUd
# d5Q54ulkyUQ9eHoj8xN9ppB0g430yyYCRirCihC7pKkFDJvtaPpoLpWgKj8qa1hJ
# Yx8JaW5amJbkg/TAj/NGK978O9C9Ne9uJa7lryft0N3zDq+ZKJeYTQ49C/IIidYf
# wzIY4vDFLc5bnrRJOQrGCsLGra7lstnbFYhRRVg4MnEnGn+x9Cf43iw6IGmYslmJ
# aG5vp7d0w0AFBqYBKig+gj8TTWYLwLNN9eGPfxxvFX1Fp3blQCplo8NdUmKGwx1j
# NpeG39rz+PIWoZon4c2ll9DuXWNB41sHnIc+BncG0QaxdR8UvmFhtfDcxhsEvt9B
# xw4o7t5lL+yX9qFcltgA1qFGvVnzl6UJS0gQmYAf0AApxbGbpT9Fdx41xtKiop96
# eiL6SJUfq/tHI4D1nvi/a7dLl+LrdXga7Oo3mXkYS//WsyNodeav+vyL6wuA6mk7
# r/ww7QRMjt/fdW1jkT3RnVZOT7+AVyKheBEyIXrvQQqxP/uozKRdwaGIm1dxVk5I
# RcBCyZt2WwqASGv9eZ/BvW1taslScxMNelDNMYIZdjCCGXICAQEwgZUwfjELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
# HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEoMCYGA1UEAxMfTWljcm9z
# b2Z0IENvZGUgU2lnbmluZyBQQ0EgMjAxMQITMwAAAlKLM6r4lfM52wAAAAACUjAN
# BglghkgBZQMEAgEFAKCBrjAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgor
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQg+XK+cp2M
# xN/+qqId7qhMSLyp36kjRDZ2tKagDy68420wQgYKKwYBBAGCNwIBDDE0MDKgFIAS
# AE0AaQBjAHIAbwBzAG8AZgB0oRqAGGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbTAN
# BgkqhkiG9w0BAQEFAASCAQARXQwnUwZp8vcRxA4HacDAYPpnwFWS2ckjBccPzW9j
# 4bbS4HKZNR/BeeBM5auixz3vfv7fXQHBRfFwBOWHmRC87ouQNVFpprqZ318rFs3q
# WuuXtjoRs6h9azO3agD+szuNPG6ssrlTXBb6j5JKdBK9Ob+cvElowNhw9MJd5Mtd
# hKATS7HG536lcgrQPgOgXsvBWZJOqNjmeupHdR5XAe3TuUqmsamQTI58xZKvHXhC
# 9awjuGz0Rmt7GVzmxvjDZucSDB90My+jkcrvM3MWnHl2cQ5UMoE8I0ASM7os7RBM
# B76FcvM9zBmt3LydYyoQKf+CH7Z0FxqeO5hB1fKjKca5oYIXADCCFvwGCisGAQQB
# gjcDAwExghbsMIIW6AYJKoZIhvcNAQcCoIIW2TCCFtUCAQMxDzANBglghkgBZQME
# AgEFADCCAVEGCyqGSIb3DQEJEAEEoIIBQASCATwwggE4AgEBBgorBgEEAYRZCgMB
# MDEwDQYJYIZIAWUDBAIBBQAEIHHrsnbY4tRt+f8P9u+cIa695DdlvCGOxuRrlaY1
# Ueo5AgZiFmEH6qQYEzIwMjIwMzI0MjMxOTE0LjUyNFowBIACAfSggdCkgc0wgcox
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1p
# Y3Jvc29mdCBBbWVyaWNhIE9wZXJhdGlvbnMxJjAkBgNVBAsTHVRoYWxlcyBUU1Mg
# RVNOOkFFMkMtRTMyQi0xQUZDMSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFt
# cCBTZXJ2aWNloIIRVzCCBwwwggT0oAMCAQICEzMAAAGWSVti4S/d908AAQAAAZYw
# DQYJKoZIhvcNAQELBQAwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0
# b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3Jh
# dGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwHhcN
# MjExMjAyMTkwNTEzWhcNMjMwMjI4MTkwNTEzWjCByjELMAkGA1UEBhMCVVMxEzAR
# BgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1p
# Y3Jvc29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJpY2Eg
# T3BlcmF0aW9uczEmMCQGA1UECxMdVGhhbGVzIFRTUyBFU046QUUyQy1FMzJCLTFB
# RkMxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2UwggIiMA0G
# CSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDSH2wQC2+t/jzA6jL6LZMhDNJG0nv1
# cUqe+H4MGKyEgRZUwp1YsHl1ITGyi8K9rkPRKKKAi0lT8g0b1GIipkWc8qCtE3wi
# bxoNR4mCyrvgEsXutnbxI1obx8cMfa2XgchG/XBGZcFtGd0UQvXkxUYvokfG1TyB
# MqnIZvQ2LtcmGj86laPRNuRodkEM7VVUO2oMSHJbaTNj1b2kAC8sqlytH1zmfrQp
# TA3rZOyEmywT43DRfsNlXmkNKMiW7BafNnHZLGHGacpimE4doDMur3yiH/qCCx2P
# O4pIqkA6WLGSN8yhYavcQZRFVtsl/x/IiuL0fxPGpQmRc84m41yauncveNh/5/14
# MqsZ7ugY1ix8fkOYgJBlLss8myPhaMA6qcEB/RWWqcCfhyARNjCcmBNGNXeMgKyZ
# /+e3bCOlXmWeDtVJDLmOtzEDBLmkg2/etp3T9hOX+LodYwdBkY2noCDEzPWVa834
# AmkJvR6ynEeBGj6ouWifpXxaobBdasb0+r/9eYr+T00yrLFn16rrTULnVzkW7lLy
# XWEousvzYnul3HPCQooQS4LY1HBKTyTSftGX56ZgOz7Rk+esvbcr+NjLvBBy7Xeo
# mgkuw1F/Uru7lZ9AR+EQbpg2pvCHSarMQQHbf1GXPhlDTHwkeskRiz5jPjTr1Wz/
# f+9CZx5ovtTF0QIDAQABo4IBNjCCATIwHQYDVR0OBBYEFNLfCNksLmWtIGEsiYuE
# KprRzXSyMB8GA1UdIwQYMBaAFJ+nFV0AXmJdg/Tl0mWnG1M1GelyMF8GA1UdHwRY
# MFYwVKBSoFCGTmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01p
# Y3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNybDBsBggrBgEF
# BQcBAQRgMF4wXAYIKwYBBQUHMAKGUGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9w
# a2lvcHMvY2VydHMvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAo
# MSkuY3J0MAwGA1UdEwEB/wQCMAAwEwYDVR0lBAwwCgYIKwYBBQUHAwgwDQYJKoZI
# hvcNAQELBQADggIBAK9gCxC4IVbYKVQBHP5ztJc/kfgSubcL5hTReVE1uwSVKp92
# Sfd/IIvFgGQcwVlAZc8DubOhTshlR2fSFfK6+sUzoMOuf9ItKF7m348+SpZ455iI
# TDyTgEjqXhTmTTvBfyEHA6gxHGzVo578k2Qsc7qSuXmPr8ZkeuRNHNOxFRQmnUWm
# dTOLGJlbJq9zTH+KYbnJZ2tK5xwT2d2irtBu7U/FruzCxSbnM00y6dpYZcMUCdLu
# zxHEnX8/epO1nQlrpUTpJ6gel2Pv+E+4oktdX8zz0Y0WfwdQOZVbn5gr/wPLvIoc
# eKJJ366AA36lbc8Do5h6TSvJbVArNutbg/1JcCT5Tl9peMEmiK1b3z5kRFZffztU
# e9pNYnhijkGaQnRTbsBqXaCCLmPU9i4PEHcOyh8z7t5tzjOAnQYXi7oNBbRXitz8
# XbPK2XasNB9QaU+01TKZRlVtYlsWrDriN7xCwCcx4bUnyiHGNiV5reIsDMbCKZ7h
# 1sxLIQeg5tW/Mg3R30EnzjFV5cq8RPXvoaFj89LpFMlmJbk8+KFmHzwXcl5wS+GV
# y38VulA+36aEM4FADKqMjW10FCUEVVfznFZ3UlGdSS7GqyFeoXBzEqvwaIWxv0BX
# vLtNPfR+YxOzeCaeiMVC3cx0PlDcz+AF/VN2WHKI81dOAmE/qLJkd/EpmLZzMIIH
# cTCCBVmgAwIBAgITMwAAABXF52ueAptJmQAAAAAAFTANBgkqhkiG9w0BAQsFADCB
# iDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1Jl
# ZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMp
# TWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IDIwMTAwHhcNMjEw
# OTMwMTgyMjI1WhcNMzAwOTMwMTgzMjI1WjB8MQswCQYDVQQGEwJVUzETMBEGA1UE
# CBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9z
# b2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQ
# Q0EgMjAxMDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAOThpkzntHIh
# C3miy9ckeb0O1YLT/e6cBwfSqWxOdcjKNVf2AX9sSuDivbk+F2Az/1xPx2b3lVNx
# WuJ+Slr+uDZnhUYjDLWNE893MsAQGOhgfWpSg0S3po5GawcU88V29YZQ3MFEyHFc
# UTE3oAo4bo3t1w/YJlN8OWECesSq/XJprx2rrPY2vjUmZNqYO7oaezOtgFt+jBAc
# nVL+tuhiJdxqD89d9P6OU8/W7IVWTe/dvI2k45GPsjksUZzpcGkNyjYtcI4xyDUo
# veO0hyTD4MmPfrVUj9z6BVWYbWg7mka97aSueik3rMvrg0XnRm7KMtXAhjBcTyzi
# YrLNueKNiOSWrAFKu75xqRdbZ2De+JKRHh09/SDPc31BmkZ1zcRfNN0Sidb9pSB9
# fvzZnkXftnIv231fgLrbqn427DZM9ituqBJR6L8FA6PRc6ZNN3SUHDSCD/AQ8rdH
# GO2n6Jl8P0zbr17C89XYcz1DTsEzOUyOArxCaC4Q6oRRRuLRvWoYWmEBc8pnol7X
# KHYC4jMYctenIPDC+hIK12NvDMk2ZItboKaDIV1fMHSRlJTYuVD5C4lh8zYGNRiE
# R9vcG9H9stQcxWv2XFJRXRLbJbqvUAV6bMURHXLvjflSxIUXk8A8FdsaN8cIFRg/
# eKtFtvUeh17aj54WcmnGrnu3tz5q4i6tAgMBAAGjggHdMIIB2TASBgkrBgEEAYI3
# FQEEBQIDAQABMCMGCSsGAQQBgjcVAgQWBBQqp1L+ZMSavoKRPEY1Kc8Q/y8E7jAd
# BgNVHQ4EFgQUn6cVXQBeYl2D9OXSZacbUzUZ6XIwXAYDVR0gBFUwUzBRBgwrBgEE
# AYI3TIN9AQEwQTA/BggrBgEFBQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29t
# L3BraW9wcy9Eb2NzL1JlcG9zaXRvcnkuaHRtMBMGA1UdJQQMMAoGCCsGAQUFBwMI
# MBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMAsGA1UdDwQEAwIBhjAPBgNVHRMB
# Af8EBTADAQH/MB8GA1UdIwQYMBaAFNX2VsuP6KJcYmjRPZSQW9fOmhjEMFYGA1Ud
# HwRPME0wS6BJoEeGRWh0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3By
# b2R1Y3RzL01pY1Jvb0NlckF1dF8yMDEwLTA2LTIzLmNybDBaBggrBgEFBQcBAQRO
# MEwwSgYIKwYBBQUHMAKGPmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2kvY2Vy
# dHMvTWljUm9vQ2VyQXV0XzIwMTAtMDYtMjMuY3J0MA0GCSqGSIb3DQEBCwUAA4IC
# AQCdVX38Kq3hLB9nATEkW+Geckv8qW/qXBS2Pk5HZHixBpOXPTEztTnXwnE2P9pk
# bHzQdTltuw8x5MKP+2zRoZQYIu7pZmc6U03dmLq2HnjYNi6cqYJWAAOwBb6J6Gng
# ugnue99qb74py27YP0h1AdkY3m2CDPVtI1TkeFN1JFe53Z/zjj3G82jfZfakVqr3
# lbYoVSfQJL1AoL8ZthISEV09J+BAljis9/kpicO8F7BUhUKz/AyeixmJ5/ALaoHC
# gRlCGVJ1ijbCHcNhcy4sa3tuPywJeBTpkbKpW99Jo3QMvOyRgNI95ko+ZjtPu4b6
# MhrZlvSP9pEB9s7GdP32THJvEKt1MMU0sHrYUP4KWN1APMdUbZ1jdEgssU5HLcEU
# BHG/ZPkkvnNtyo4JvbMBV0lUZNlz138eW0QBjloZkWsNn6Qo3GcZKCS6OEuabvsh
# VGtqRRFHqfG3rsjoiV5PndLQTHa1V1QJsWkBRH58oWFsc/4Ku+xBZj1p/cvBQUl+
# fpO+y/g75LcVv7TOPqUxUYS8vwLBgqJ7Fx0ViY1w/ue10CgaiQuPNtq6TPmb/wrp
# NPgkNWcr4A245oyZ1uEi6vAnQj0llOZ0dFtq0Z4+7X6gMTN9vMvpe784cETRkPHI
# qzqKOghif9lwY1NNje6CbaUFEMFxBmoQtB1VM1izoXBm8qGCAs4wggI3AgEBMIH4
# oYHQpIHNMIHKMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUw
# IwYDVQQLExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25zMSYwJAYDVQQLEx1U
# aGFsZXMgVFNTIEVTTjpBRTJDLUUzMkItMUFGQzElMCMGA1UEAxMcTWljcm9zb2Z0
# IFRpbWUtU3RhbXAgU2VydmljZaIjCgEBMAcGBSsOAwIaAxUA0PommlVZaduKtDHg
# hztBZDfmVv6ggYMwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGlu
# Z3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBv
# cmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDAN
# BgkqhkiG9w0BAQUFAAIFAOXnGMQwIhgPMjAyMjAzMjUwMDIwMjBaGA8yMDIyMDMy
# NjAwMjAyMFowdzA9BgorBgEEAYRZCgQBMS8wLTAKAgUA5ecYxAIBADAKAgEAAgIb
# eAIB/zAHAgEAAgITfTAKAgUA5ehqRAIBADA2BgorBgEEAYRZCgQCMSgwJjAMBgor
# BgEEAYRZCgMCoAowCAIBAAIDB6EgoQowCAIBAAIDAYagMA0GCSqGSIb3DQEBBQUA
# A4GBAAyEJNgAPIarnmQp2Khs8YnZKTrXk9hz6IpvOghdDKNCnGl6Gtz7SP5aLh2N
# Ap0W89XA+XBilvHZXZgCQ8F0f6YmNGDbXUPAOh6FunVtgEQgYI0JjFIHcwzYpzn1
# PVsS/vuB5w989gTsY2qPNXFO4sCkMSc5K1fL+q3ldT0c7BRRMYIEDTCCBAkCAQEw
# gZMwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcT
# B1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UE
# AxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAGWSVti4S/d908A
# AQAAAZYwDQYJYIZIAWUDBAIBBQCgggFKMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0B
# CRABBDAvBgkqhkiG9w0BCQQxIgQgEQAAA4kbt3Eowmo4rWpMa1fnZHx0xVB8fSJT
# Yg30CkIwgfoGCyqGSIb3DQEJEAIvMYHqMIHnMIHkMIG9BCB2BNYC+B0105J2Ry6C
# fnZ0JA8JflZQQ6sLpHI3LbK9kDCBmDCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1w
# IFBDQSAyMDEwAhMzAAABlklbYuEv3fdPAAEAAAGWMCIEINyz6hJ+OSg3AIZmiF1k
# MwmRPQZZujRWDyeY/Bts5CekMA0GCSqGSIb3DQEBCwUABIICAKI5sMv1aJr+dzgi
# NdvB+HpScVkw/DDxFgfPjFzR0KnoXzkSisvd14ChqF4lZmKbr1kbKRLthbl67Hqp
# h7d13/aGAKyWaJ4uI/czFszYKKx0ujon6o8PwK+bR5sHXSDgovaqf9VzFWbb7nSt
# UIBbww8jGU1F/Y+g8lrBKZ/SUizehdd/p7ntFtNjJdwWSo/izL/J0ZV4yW6eAd4G
# dlolk5ZrvXSW+RDTmdKmIP0neVDgE/mP5oHh3hyyuiCNau+aqz1TkjreW5IL5cv/
# WgRL/96ggITx+v7tpM+oBYTFSFiXCsjpvqhjfBfPrFalUHtjguZ3kM9meYwXb3XG
# 0QlJo+n10D7ud++o9h4C8AnWPfpYwRsVV/9G3T9eS8WSYsXBvOC3/Qom6vUCDMEG
# cUXe7qTeqnJMLUvOElUhb2hxKoan98ooCrQR6ks+Z9gakNtlxKamaDtyV8m+oNOJ
# eJCsL/JpopW31+PPHpiDKFUIsy03zTgEpRh5KgxvL/pgloo+V0I8AtEj5urCFCbQ
# jdaUFBYRvSUjm+5cTOW40AFo3UCAECxNBI4Hx6ca9/K4d2lQLmuvFjGLc1+sCfeL
# rwfFQxebsREYUHgXKzD1PUv7y8sHl5qjFxShAyQ6wAeaXixlFwObG09MJJ2vT/cP
# H1Ed3UsghqZ1c9Gstz89njuCU9CM
# SIG # End signature block
