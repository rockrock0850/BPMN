package com.ebizprise.bpmn.io;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.ModelAndView;

@RestController
public class AppController {

	@GetMapping("/")
	public ModelAndView main (ModelAndView model) {
		return new ModelAndView("index");
	}

	@GetMapping("/hello/{name}")
	public ModelAndView mainWithParam (@PathVariable String name, ModelAndView model) {
		model.setViewName("index");
		model.addObject("message", name);

		return model;
	}

}
