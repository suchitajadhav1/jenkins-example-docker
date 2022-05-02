# https://hub.docker.com/_/microsoft-dotnet
FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /source

# copy csproj and restore as distinct layers
COPY complexapp/complexapp/*.csproj complexapp/
COPY complexapp/libfoo/*.csproj libfoo/
COPY complexapp/libbar/*.csproj libbar/
RUN dotnet restore complexapp/complexapp.csproj

# copy and build app and libraries
COPY complexapp/ complexapp/
COPY complexapp/libfoo/ libfoo/
COPY complexapp/libbar/ libbar/
WORKDIR /source/complexapp
RUN dotnet build -c release -restore

# test stage -- exposes optional entrypoint
# target entrypoint with: docker build --target test
FROM build AS test
WORKDIR /source/tests
COPY complexapp/tests/ .
ENTRYPOINT ["dotnet", "test", "--logger:trx"]

FROM build AS publish
RUN dotnet publish -c release --no-build -o /app

# final stage/image
FROM mcr.microsoft.com/dotnet/runtime:6.0
WORKDIR /app
COPY --from=publish /app .
ENTRYPOINT ["dotnet", "complexapp.dll"]
