## Jellyfin Azure Lab

After getting the AZ104, I wanted to solidify my knowledge with a more in-depth project that put many of the pieces together. I also want to take the opportunity to delve more into IaC, as it wasn't covered much.

While none of this is likely "Best practice", I want to include the following:
- VM Scale Set running the jellyfin docker container
- Network Security Group to limit access to scale set subnet
- Application gateway to load balance scale set
- VPN Gateway for private management of scale set
- Azure File Share attached to the scale set to host media for the jellyfin application

I also want to be able to deploy all of this automatically via IaC. In this case, Bicep. I currently have an NSG, Vnet, and VM configured in my bicep script. Many pieces of it will change over time as I further deploy this application.

<img src="https://i.imgur.com/Eud5uFY.png"></img>
