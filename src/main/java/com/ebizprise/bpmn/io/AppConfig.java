package com.ebizprise.bpmn.io;

import org.camunda.bpm.engine.ProcessEngine;
import org.camunda.bpm.engine.ProcessEngineConfiguration;
import org.camunda.bpm.engine.spring.SpringProcessEngineConfiguration;
import org.camunda.bpm.engine.spring.annotations.ProcessEngineComponent;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.boot.web.servlet.support.SpringBootServletInitializer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Primary;
import org.springframework.context.annotation.PropertySource;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@SpringBootApplication
@ProcessEngineComponent
@PropertySource({ "classpath:resources.properties" })
@ComponentScan(basePackages = { "com.ebizprise.bpmn.io" })
public class AppConfig extends SpringBootServletInitializer implements WebMvcConfigurer {

	@Override
	public void addResourceHandlers (ResourceHandlerRegistry registry) {
		registry.addResourceHandler("/static/**").addResourceLocations("/WEB-INF/static/");
	}

	@Override
	protected SpringApplicationBuilder configure (SpringApplicationBuilder application) {
		return application.sources(AppConfig.class);
	}

	@Bean
	@Primary
	public ProcessEngine ProcessEngineConfiguration () {
		ProcessEngine processEngine = SpringProcessEngineConfiguration.createStandaloneInMemProcessEngineConfiguration()
				.setJobExecutorActivate(true).setHistory(ProcessEngineConfiguration.HISTORY_FULL)
				.setJdbcUrl("jdbc:h2:mem:camunda;DB_CLOSE_DELAY=1000")
				.setDatabaseSchemaUpdate(ProcessEngineConfiguration.DB_SCHEMA_UPDATE_TRUE).buildProcessEngine();

		return processEngine;
	}

	public static void main (String[] args) {
		SpringApplication.run(AppConfig.class, args);
	}

}
