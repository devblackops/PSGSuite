function New-GSCourse {
    <#
    .SYNOPSIS
    Creates a course.

    .DESCRIPTION
    Creates a course.

    .PARAMETER Name
    Name of the course. For example, "10th Grade Biology". The name is required. It must be between 1 and 750 characters and a valid UTF-8 string.

    .PARAMETER OwnerId
    The identifier of the owner of a course.

    When specified as a parameter of a create course request, this field is required. The identifier can be one of the following:

    * the numeric identifier for the user
    * the email address of the user
    * the string literal "me", indicating the requesting user

    .PARAMETER Id
    Identifier for this course assigned by Classroom.

    When creating a course, you may optionally set this identifier to an alias string in the request to create a corresponding alias. The id is still assigned by Classroom and cannot be updated after the course is created.

    .PARAMETER Section
    Section of the course. For example, "Period 2". If set, this field must be a valid UTF-8 string and no longer than 2800 characters.

    .PARAMETER DescriptionHeading
    Optional heading for the description. For example, "Welcome to 10th Grade Biology." If set, this field must be a valid UTF-8 string and no longer than 3600 characters.

    .PARAMETER Description
    Optional description. For example, "We'll be learning about the structure of living creatures from a combination of textbooks, guest lectures, and lab work. Expect to be excited!" If set, this field must be a valid UTF-8 string and no longer than 30,000 characters.

    .PARAMETER Room
    Optional room location. For example, "301". If set, this field must be a valid UTF-8 string and no longer than 650 characters.

    .PARAMETER CourseState
    State of the course. If unspecified, the default state is PROVISIONED

    Available values are:
    * ACTIVE - The course is active.
    * ARCHIVED - The course has been archived. You cannot modify it except to change it to a different state.
    * PROVISIONED - The course has been created, but not yet activated. It is accessible by the primary teacher and domain administrators, who may modify it or change it to the ACTIVE or DECLINED states. A course may only be changed to PROVISIONED if it is in the DECLINED state.
    * DECLINED - The course has been created, but declined. It is accessible by the course owner and domain administrators, though it will not be displayed in the web UI. You cannot modify the course except to change it to the PROVISIONED state. A course may only be changed to DECLINED if it is in the PROVISIONED state.

    .EXAMPLE
    New-GSCourse -Name "The Rebublic" -OwnerId plato@athens.edu -Id the-republic-s01 -Section s01 -DescriptionHeading "The definition of justice, the order and character of the just city-state and the just man" -Room academy-01
    #>
    [cmdletbinding()]
    Param
    (
        [parameter(Mandatory = $true,Position = 0)]
        [ValidateLength(1,750)]
        [String]
        $Name,
        [parameter(Mandatory = $false)]
        [Alias('Teacher')]
        [String]
        $OwnerId,
        [parameter(Mandatory = $false)]
        [Alias('Alias')]
        [String]
        $Id,
        [parameter(Mandatory = $false)]
        [ValidateLength(1,2800)]
        [String]
        $Section,
        [parameter(Mandatory = $false)]
        [ValidateLength(1,3600)]
        [Alias('Heading')]
        [String]
        $DescriptionHeading,
        [parameter(Mandatory = $false)]
        [ValidateLength(1,30000)]
        [String]
        $Description,
        [parameter(Mandatory = $false)]
        [String]
        $Room,
        [parameter(Mandatory = $false)]
        [Alias('Status')]
        [ValidateSet('PROVISIONED','ACTIVE','ARCHIVED','DECLINED')]
        [String]
        $CourseState
    )
    Begin {
        $serviceParams = @{
            Scope       = 'https://www.googleapis.com/auth/classroom.courses'
            ServiceType = 'Google.Apis.Classroom.v1.ClassroomService'
        }
        $service = New-GoogleService @serviceParams
    }
    Process {
        try {
            Write-Verbose "Creating new Course '$Name'"
            $body = New-Object 'Google.Apis.Classroom.v1.Data.Course'
            foreach ($prop in $PSBoundParameters.Keys | Where-Object {$body.PSObject.Properties.Name -contains $_}) {
                switch ($prop) {
                    OwnerId {
                        try {
                            [decimal]$PSBoundParameters[$prop] | Out-Null
                        }
                        catch {
                            if ($PSBoundParameters[$prop] -ceq 'me') {
                                $PSBoundParameters[$prop] = $Script:PSGSuite.AdminEmail
                            }
                            elseif ($PSBoundParameters[$prop] -notlike "*@*.*") {
                                $PSBoundParameters[$prop] = "$($PSBoundParameters[$prop])@$($Script:PSGSuite.Domain)"
                            }
                        }
                        $body.$prop = $PSBoundParameters[$prop]
                    }
                    Default {
                        $body.$prop = $PSBoundParameters[$prop]
                    }
                }
            }
            if ($PSBoundParameters.Keys -notcontains 'OwnerId') {
                $body.OwnerId = $Script:PSGSuite.AdminEmail
            }
            $request = $service.Courses.Create($body)
            $request.Execute()
        }
        catch {
            if ($ErrorActionPreference -eq 'Stop') {
                $PSCmdlet.ThrowTerminatingError($_)
            }
            else {
                Write-Error $_
            }
        }
    }
}
