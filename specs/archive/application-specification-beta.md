# **Basic description**

A community needs to log track and be able to produce reports or report on municiple service issues. This includes for now, but will be expanded, potholes / road damage, broken traffic lights, water pipe leaks, sewerage pipe leaks and broken street lights.

The idea is that the community member uses an application on a smart phone to take photo's as evidence. They then classify the type of issue and it is sent of to a central web service which logs it with the location info date and time from the photo. This is all stored on a database that can be used for reporting tracking and status updates on these issues. A management interface for the application administrators as a web application should also be available.

Community members can then also use the mobile app to view issues in the community as well as statuses etc.

# Technical

This app might reach massive scale but should basically be managed per community or group of communities in larger urban areas. Lets call each instance a pod. A pod can contain multiple communities, this can be towns, regions / wards within towns and urban areas. A pod will be a a single instance of a cloud application running independant of other instances with its own cload setup infrastructure and database(s). Yes it will be a cload hosted system. So a pod needs to also have its management structure and administration level. Then a comunity administration exists within a pod for a specific community. The overall system will then be administered by a central application authority responsible for setting up the different pods.

The app itself will consist of a database, web service, mobile app and web application. There might be multiples of these but more investigation needs to be done to get to the specific technical make-up and best technologies for the purpose.

Where possible AI should be used to help with the data management and image management and recognisions as well as to filter out bad users and photos.

This will be an open source project. Communities should only pay for admin and hosting costs no licencing.

The application should also cater for different languages, so community members and administrators can use the language of their choice.

# To Do

- What layers of applications will be involved

- What development languages and frameworks will be best for each layer.

- What database types and or makes will be best

- what are the cloud requirments

- What cloud service provider will be best

- What levels of cloud infrastructure depending on usage will be best.

- Explore each layer, get the details of what functionality is needed to get to development point.

- What theme to use.
