#See https://aka.ms/customizecontainer to learn how to customize your debug container and how Visual Studio uses this Dockerfile to build your images for faster debugging.

FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM jenkins/jenkins:latest

USER root

# Install prerequisites for .NET SDK
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       curl \
       wget \
       apt-transport-https \
       software-properties-common

# Install the .NET SDK
RUN wget -q https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
       dotnet-sdk-6.0

USER jenkins

FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src
COPY ["devops.csproj", "."]
RUN dotnet restore "./devops.csproj"
COPY . .
WORKDIR "/src/."
RUN dotnet build "devops.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "devops.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "devops.dll"]

