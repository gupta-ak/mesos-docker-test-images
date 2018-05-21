$ErrorActionPreference = "Stop"

$windowsVersions = @("sac2016", "1709", "1803")
$imageNames = @("https-server", "inky", "nano-admin")

foreach ($name in $imageNames)
{
    $images = @()
    foreach ($winver in $windowsVersions)
    {
        $imageName = "akagup/${name}:$winver"

        # Causes an error and it's not needed anyway, since the default sac2016 nanoserver image is admin.
        if ($name -eq "nano-admin" -and $winver -eq "sac2016") {
            docker pull "microsoft/nanoserver:sac2016"
            if ($LASTEXITCODE -ne 0)
            {
                Write-Error "Failed to pull microsoft/nanoserver:sac2016"
            }

            docker tag "microsoft/nanoserver:sac2016" $imageName
            if ($LASTEXITCODE -ne 0)
            {
                Write-Error "Failed to tag $imageName"
            }

            docker push $imageName
            if ($LASTEXITCODE -ne 0)
            {
                Write-Error "Failed to push $imageName"
            }

            $images += $imageName
            continue
        }

        # Build the image
        docker build --pull --build-arg VERSION=$winver --isolation=hyperv -t $imageName $name
        if ($LASTEXITCODE -ne 0)
        {
            Write-Error "Failed to build $imageName"
        }

        # Verify that the image runs
        docker run --entrypoint=cmd --rm --isolation=hyperv $imageName /c echo running image $imageName  
        if ($LASTEXITCODE -ne 0)
        {
            Write-Error "Failed to run $imageName"
        }

        # Push to docker hub
        docker push $imageName
        if ($LASTEXITCODE -ne 0)
        {
            Write-Error "Failed to push $imageName"
        }

        $images += $imageName
    }

    # Create manifest list
    $manifestList = "docker.io/akagup/${name}:latest"
    docker manifest create  $manifestList @images
    if ($LASTEXITCODE -ne 0)
    {
        Write-Error "Failed to create manifest list $manifestList"
    }

    # Upload manifest
    docker manifest push -p $manifestList
    if ($LASTEXITCODE -ne 0)
    {
        Write-Error "Failed to push manifest list $manifestList"
    }
}